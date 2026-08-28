import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Result codes for a sync attempt.
enum GitSyncStatus {
  success,
  conflict,
  error,
  notGitRepo,
}

class GitSyncResult {
  GitSyncResult({
    required this.status,
    this.message,
    this.conflictFiles = const <String>[],
  });

  final GitSyncStatus status;
  final String? message;
  final List<String> conflictFiles;
}

class GitVaultStatus {
  GitVaultStatus({
    required this.isGitRepo,
    required this.isDirty,
    required this.conflictFiles,
  });

  final bool isGitRepo;
  final bool isDirty;
  final List<String> conflictFiles;
}

/// A small wrapper around system `git` CLI for syncing a Vault folder.
///
/// MVP behavior:
/// - ensure git repository exists (git init if needed)
/// - set remote url (origin) if provided
/// - pull --rebase
/// - if local changes exist, commit -am `Nightelf sync <timestamp>`
/// - push
/// - detect conflicts by `git diff --name-only --diff-filter=U`
class GitSyncService {
  GitSyncService({this.gitExecutable = 'git'});

  final String gitExecutable;

  String _humanizeGitError(String raw) {
    final text = raw.trim();
    if (text.contains('cannot be used within an App Sandbox') ||
        text.contains('App Sandbox')) {
      return '当前应用启用了 macOS App Sandbox，系统禁止在沙盒内运行 git/xcrun。\n'
          '解决：关闭 App Sandbox（调试构建）或使用非沙盒的辅助进程来执行同步。';
    }
    if (_looksLikeRebaseLock(text)) {
      return '本地 Git 卡在未完成的 rebase。Nightelf 会自动中止并重试同步。';
    }
    return text;
  }

  bool _looksLikeRebaseLock(String text) {
    final lower = text.toLowerCase();
    return lower.contains('rebase-merge') ||
        lower.contains('rebase-apply') ||
        lower.contains('you are in the middle of another rebase') ||
        lower.contains('in the middle of a rebase') ||
        (lower.contains('rebase') && lower.contains('in progress'));
  }

  Future<bool> _isRebaseInProgress(String repoPath) async {
    final rebaseMerge = Directory('$repoPath/.git/rebase-merge');
    final rebaseApply = Directory('$repoPath/.git/rebase-apply');
    if (await rebaseMerge.exists() || await rebaseApply.exists()) {
      return true;
    }
    final status = await _run(
      args: ['status'],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    return _looksLikeRebaseLock('${status.stdout}\n${status.stderr}');
  }

  Future<void> _abortRebase(String repoPath) async {
    await _run(
      args: ['rebase', '--abort'],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    // Stale lock dirs can remain if abort itself failed.
    for (final name in const ['rebase-merge', 'rebase-apply']) {
      final dir = Directory('$repoPath/.git/$name');
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  /// Clears an interrupted/stale rebase so the next pull can start.
  Future<void> _ensureNoInterruptedRebase(String repoPath) async {
    if (await _isRebaseInProgress(repoPath)) {
      await _abortRebase(repoPath);
    }
  }

  /// Pull with recovery: abort stuck rebase, try rebase, then fall back to merge.
  Future<GitSyncResult> _pullWithRecovery({
    required String repoPath,
    required String branch,
    required void Function(String resolvedBranch) onBranchResolved,
    bool allowEmptyRemote = false,
  }) async {
    await _ensureNoInterruptedRebase(repoPath);

    Future<({int exitCode, String stdout, String stderr})> runPull({
      required String tryBranch,
      required bool rebase,
    }) async {
      final pull = await _run(
        args: [
          'pull',
          if (rebase) '--rebase' else '--no-rebase',
          'origin',
          tryBranch,
        ],
        workingDirectory: repoPath,
        allowNonZeroExit: true,
      );
      return (exitCode: pull.exitCode, stdout: pull.stdout, stderr: pull.stderr);
    }

    Future<GitSyncResult?> tryResolveMissingBranch(
      String tryBranch,
      String stderr,
      String stdout,
    ) async {
      if (!_looksLikeMissingRemoteRef(stderr) &&
          !_looksLikeEmptyRemote(stderr, stdout)) {
        return null;
      }
      final resolved = await _resolveRemoteDefaultBranch(
        repoPath: repoPath,
        remoteName: 'origin',
      );
      if (resolved != null && resolved != tryBranch) {
        return _pullWithRecovery(
          repoPath: repoPath,
          branch: resolved,
          onBranchResolved: onBranchResolved,
          allowEmptyRemote: allowEmptyRemote,
        );
      }
      if (allowEmptyRemote) {
        onBranchResolved(tryBranch);
        return GitSyncResult(status: GitSyncStatus.success);
      }
      return null;
    }

    var tryBranch = branch;
    var pull = await runPull(tryBranch: tryBranch, rebase: true);

    if (pull.exitCode == 0) {
      onBranchResolved(tryBranch);
      return GitSyncResult(status: GitSyncStatus.success);
    }

    final missing = await tryResolveMissingBranch(
      tryBranch,
      pull.stderr,
      pull.stdout,
    );
    if (missing != null) {
      return missing;
    }

    // Stuck rebase lock from a previous attempt: abort and retry once.
    if (_looksLikeRebaseLock('${pull.stderr}\n${pull.stdout}') ||
        await _isRebaseInProgress(repoPath)) {
      await _abortRebase(repoPath);
      pull = await runPull(tryBranch: tryBranch, rebase: true);
      if (pull.exitCode == 0) {
        onBranchResolved(tryBranch);
        return GitSyncResult(status: GitSyncStatus.success);
      }
      final missingAfterAbort = await tryResolveMissingBranch(
        tryBranch,
        pull.stderr,
        pull.stdout,
      );
      if (missingAfterAbort != null) {
        return missingAfterAbort;
      }
    }

    // Rebase couldn't complete cleanly — abort and try a merge pull.
    if (await _isRebaseInProgress(repoPath)) {
      await _abortRebase(repoPath);
    }
    final merge = await runPull(tryBranch: tryBranch, rebase: false);
    if (merge.exitCode == 0) {
      onBranchResolved(tryBranch);
      return GitSyncResult(status: GitSyncStatus.success);
    }

    final missingMerge = await tryResolveMissingBranch(
      tryBranch,
      merge.stderr,
      merge.stdout,
    );
    if (missingMerge != null) {
      return missingMerge;
    }

    final conflicts = await _listConflicts(repoPath);
    if (conflicts.isNotEmpty) {
      return GitSyncResult(
        status: GitSyncStatus.conflict,
        message: '拉取后存在冲突，需要手动解决后重试同步。',
        conflictFiles: conflicts,
      );
    }

    final detail = merge.stderr.trim().isEmpty ? merge.stdout : merge.stderr;
    final rebaseDetail = pull.stderr.trim().isEmpty ? pull.stdout : pull.stderr;
    return GitSyncResult(
      status: GitSyncStatus.error,
      message:
          'pull 失败：${_humanizeGitError(detail.trim().isEmpty ? rebaseDetail : detail)}',
    );
  }

  Future<String?> _resolveRemoteDefaultBranch({
    required String repoPath,
    required String remoteName,
  }) async {
    // Try: git symbolic-ref --short refs/remotes/origin/HEAD
    final symbolic = await _run(
      args: ['symbolic-ref', '--short', 'refs/remotes/$remoteName/HEAD'],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    if (symbolic.exitCode == 0) {
      final branch = symbolic.stdout.trim();
      if (branch.isNotEmpty) {
        // output might be "origin/main" depending on git version
        final parts = branch.split('/');
        return parts.isNotEmpty ? parts.last : branch;
      }
    }

    // Fallback: git remote show origin -> "HEAD branch: main"
    final show = await _run(
      args: ['remote', 'show', remoteName],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    final merged = '${show.stdout}\n${show.stderr}';
    final match = RegExp(r'HEAD branch:\s*(.+)\s*')
        .firstMatch(merged)
        ?.group(1)
        ?.trim();
    if (match != null && match.isNotEmpty) {
      return match;
    }

    return null;
  }

  bool _looksLikeMissingRemoteRef(String stderr) {
    final text = stderr.toLowerCase();
    return text.contains("couldn't find remote ref") ||
        text.contains('could not find remote ref') ||
        (text.contains('remote ref') && text.contains('not found')) ||
        text.contains('does not match any');
  }

  bool _looksLikeEmptyRemote(String stderr, String stdout) {
    final text = '${stderr.toLowerCase()}\n${stdout.toLowerCase()}';
    return text.contains('no such ref') ||
        text.contains("couldn't find remote ref") ||
        text.contains('does not appear to be a git repository') ||
        text.contains('remote origin does not have') ||
        text.contains('refspec') && text.contains('does not match');
  }

  /// Commits dirty working tree. Returns an error result, or null when OK.
  Future<GitSyncResult?> _commitLocalChangesIfDirty(String repoPath) async {
    final status = await _run(
      args: ['status', '--porcelain'],
      workingDirectory: repoPath,
    );
    final dirty = status.stdout.trim().isNotEmpty;
    if (!dirty) {
      return null;
    }

    await _run(
      args: ['config', 'user.name', 'Nightelf'],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    await _run(
      args: ['config', 'user.email', 'nightelf@example.com'],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );

    final add = await _run(
      args: ['add', '-A'],
      workingDirectory: repoPath,
    );
    if (add.exitCode != 0) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: 'git add 失败：${_humanizeGitError(add.stderr)}',
      );
    }

    final commit = await _run(
      args: [
        'commit',
        '-m',
        'Nightelf sync ${DateTime.now().toIso8601String()}',
      ],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    if (commit.exitCode != 0 &&
        !commit.stderr.toLowerCase().contains('nothing to commit')) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message:
            'git commit 失败：${_humanizeGitError(commit.stderr.trim().isEmpty ? commit.stdout : commit.stderr)}',
      );
    }
    return null;
  }

  Future<GitVaultStatus> statusVault(String vaultRootPath) async {
    final repoDir = Directory(vaultRootPath);
    final gitDir = Directory('${repoDir.path}/.git');
    final isRepo = await gitDir.exists();
    if (!isRepo) {
      return GitVaultStatus(
        isGitRepo: false,
        isDirty: false,
        conflictFiles: const <String>[],
      );
    }

    final conflicts = await _listConflicts(repoDir.path);
    final status = await _run(
      args: ['status', '--porcelain'],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    final dirty = status.stdout.trim().isNotEmpty;

    return GitVaultStatus(
      isGitRepo: true,
      isDirty: dirty,
      conflictFiles: conflicts,
    );
  }

  Future<void> initRepo(String vaultRootPath) async {
    final repoDir = Directory(vaultRootPath);
    final gitDir = Directory('${repoDir.path}/.git');
    if (await gitDir.exists()) {
      return;
    }
    final init = await _run(
      args: ['init'],
      workingDirectory: repoDir.path,
    );
    if (init.exitCode != 0) {
      throw StateError('git init 失败：${_humanizeGitError(init.stderr)}');
    }
  }

  Future<void> addAll(String vaultRootPath) async {
    final repoDir = Directory(vaultRootPath);
    final add = await _run(
      args: ['add', '-A'],
      workingDirectory: repoDir.path,
    );
    if (add.exitCode != 0) {
      throw StateError('git add 失败：${_humanizeGitError(add.stderr)}');
    }
  }

  /// @return 是否真的产生了 commit（没有变更时返回 false）
  Future<bool> commitAll({
    required String vaultRootPath,
    required String message,
  }) async {
    final repoDir = Directory(vaultRootPath);
    final status = await _run(
      args: ['status', '--porcelain'],
      workingDirectory: repoDir.path,
    );
    final dirty = status.stdout.trim().isNotEmpty;
    if (!dirty) {
      return false;
    }

    // Ensure user identity for local commits.
    await _run(
      args: ['config', 'user.name', 'Nightelf'],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    await _run(
      args: ['config', 'user.email', 'nightelf@example.com'],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );

    final commit = await _run(
      args: ['commit', '-m', message],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );

    if (commit.exitCode != 0) {
      final stderrLower = commit.stderr.toLowerCase();
      if (stderrLower.contains('nothing to commit')) {
        return false;
      }
      return false;
    }
    return true;
  }

  /// Pull-only sync (auto pull).
  ///
  /// This does NOT commit local changes and does NOT push.
  Future<GitSyncResult> pullVault({
    required String vaultRootPath,
    required String remoteUrl,
    String branch = 'main',
  }) async {
    final repoDir = Directory(vaultRootPath);
    if (!await repoDir.exists()) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: 'Vault 目录不存在：$vaultRootPath',
      );
    }
    if (remoteUrl.trim().isEmpty) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: '未填写 remote URL。',
      );
    }

    // ensure repo
    final gitDir = Directory('${repoDir.path}/.git');
    if (!await gitDir.exists()) {
      final init = await _run(
        args: ['init'],
        workingDirectory: repoDir.path,
      );
      if (init.exitCode != 0) {
        return GitSyncResult(
          status: GitSyncStatus.error,
          message: 'git init 失败：${_humanizeGitError(init.stderr)}',
        );
      }
    }

    // configure remote
    final remoteSet = await _run(
      args: ['remote', 'remove', 'origin'],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (remoteSet.exitCode != 0) {
      // ignore
    }
    final remoteAdd = await _run(
      args: ['remote', 'add', 'origin', remoteUrl],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (remoteAdd.exitCode != 0) {
      final remoteSetUrl = await _run(
        args: ['remote', 'set-url', 'origin', remoteUrl],
        workingDirectory: repoDir.path,
        allowNonZeroExit: true,
      );
      if (remoteSetUrl.exitCode != 0) {
        return GitSyncResult(
          status: GitSyncStatus.error,
          message:
              '设置 remote 失败：${_humanizeGitError(remoteAdd.stderr)}',
        );
      }
    }

    // pull (with stuck-rebase recovery + merge fallback)
    return _pullWithRecovery(
      repoPath: repoDir.path,
      branch: branch,
      onBranchResolved: (_) {},
      allowEmptyRemote: false,
    );
  }

  /// Push-only sync (auto push).
  ///
  /// This does NOT pull and does NOT commit local changes.
  Future<GitSyncResult> pushVault({
    required String vaultRootPath,
    required String remoteUrl,
    String branch = 'main',
  }) async {
    final repoDir = Directory(vaultRootPath);
    if (!await repoDir.exists()) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: 'Vault 目录不存在：$vaultRootPath',
      );
    }
    if (remoteUrl.trim().isEmpty) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: '未填写 remote URL。',
      );
    }

    // ensure repo
    final gitDir = Directory('${repoDir.path}/.git');
    if (!await gitDir.exists()) {
      final init = await _run(
        args: ['init'],
        workingDirectory: repoDir.path,
      );
      if (init.exitCode != 0) {
        return GitSyncResult(
          status: GitSyncStatus.error,
          message: 'git init 失败：${_humanizeGitError(init.stderr)}',
        );
      }
    }

    // configure remote
    final remoteSet = await _run(
      args: ['remote', 'remove', 'origin'],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (remoteSet.exitCode != 0) {}
    final remoteAdd = await _run(
      args: ['remote', 'add', 'origin', remoteUrl],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (remoteAdd.exitCode != 0) {
      final remoteSetUrl = await _run(
        args: ['remote', 'set-url', 'origin', remoteUrl],
        workingDirectory: repoDir.path,
        allowNonZeroExit: true,
      );
      if (remoteSetUrl.exitCode != 0) {
        return GitSyncResult(
          status: GitSyncStatus.error,
          message:
              '设置 remote 失败：${_humanizeGitError(remoteAdd.stderr)}',
        );
      }
    }

    // push
    var branchForPush = branch;
    Future<GitSyncResult> attemptPush(String tryBranch) async {
      final push = await _run(
        args: ['push', 'origin', tryBranch],
        workingDirectory: repoDir.path,
        allowNonZeroExit: true,
      );
      if (push.exitCode == 0) {
        branchForPush = tryBranch;
        return GitSyncResult(status: GitSyncStatus.success);
      }

      if (_looksLikeMissingRemoteRef(push.stderr)) {
        final resolved = await _resolveRemoteDefaultBranch(
          repoPath: repoDir.path,
          remoteName: 'origin',
        );
        if (resolved != null && resolved != tryBranch) {
          return attemptPush(resolved);
        }
      }

      return GitSyncResult(
        status: GitSyncStatus.error,
        message:
            'push 失败：${_humanizeGitError(push.stderr.trim().isEmpty ? push.stdout : push.stderr)}',
      );
    }

    final pushResult = await attemptPush(branchForPush);
    if (pushResult.status != GitSyncStatus.success) {
      return pushResult;
    }
    return GitSyncResult(status: GitSyncStatus.success);
  }

  Future<GitSyncResult> syncVault({
    required String vaultRootPath,
    required String remoteUrl,
    String branch = 'main',
  }) async {
    final repoDir = Directory(vaultRootPath);
    if (!await repoDir.exists()) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: 'Vault 目录不存在：$vaultRootPath',
      );
    }
    if (remoteUrl.trim().isEmpty) {
      return GitSyncResult(
        status: GitSyncStatus.error,
        message: '未填写 remote URL。',
      );
    }

    // 1) ensure repository
    final gitDir = Directory('${repoDir.path}/.git');
    if (!await gitDir.exists()) {
      final init = await _run(
        args: ['init'],
        workingDirectory: repoDir.path,
      );
      if (init.exitCode != 0) {
        return GitSyncResult(
          status: GitSyncStatus.error,
          message: 'git init 失败：${_humanizeGitError(init.stderr)}',
        );
      }
    }

    // 2) configure remote
    final remoteSet = await _run(
      args: ['remote', 'remove', 'origin'],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (remoteSet.exitCode != 0) {
      // ignore
    }
    final remoteAdd = await _run(
      args: ['remote', 'add', 'origin', remoteUrl],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (remoteAdd.exitCode != 0) {
      final remoteSetUrl = await _run(
        args: ['remote', 'set-url', 'origin', remoteUrl],
        workingDirectory: repoDir.path,
        allowNonZeroExit: true,
      );
      if (remoteSetUrl.exitCode != 0) {
        return GitSyncResult(
          status: GitSyncStatus.error,
          message:
              '设置 remote 失败：${_humanizeGitError(remoteAdd.stderr)}',
        );
      }
    }

    // 3) commit local changes FIRST so `pull --rebase` is not blocked
    // by unstaged/uncommitted files.
    final preCommit = await _commitLocalChangesIfDirty(repoDir.path);
    if (preCommit != null) {
      return preCommit;
    }

    // Prefer `main` locally for empty remotes / first push.
    await _run(
      args: ['branch', '-M', branch],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );

    // 4) pull with stuck-rebase recovery + merge fallback
    var branchForPush = branch;
    final pullResult = await _pullWithRecovery(
      repoPath: repoDir.path,
      branch: branch,
      onBranchResolved: (resolved) => branchForPush = resolved,
      allowEmptyRemote: true,
    );
    if (pullResult.status != GitSyncStatus.success) {
      return pullResult;
    }

    // 5) push (create upstream on first sync)
    final push = await _run(
      args: ['push', '-u', 'origin', branchForPush],
      workingDirectory: repoDir.path,
      allowNonZeroExit: true,
    );
    if (push.exitCode != 0) {
      final conflicts = await _listConflicts(repoDir.path);
      if (conflicts.isNotEmpty) {
        return GitSyncResult(
          status: GitSyncStatus.conflict,
          message: 'push 前后存在冲突，需要手动处理。',
          conflictFiles: conflicts,
        );
      }
      return GitSyncResult(
        status: GitSyncStatus.error,
        message:
            'push 失败：${_humanizeGitError(push.stderr.trim().isEmpty ? push.stdout : push.stderr)}',
      );
    }

    return GitSyncResult(status: GitSyncStatus.success);
  }

  Future<List<String>> _listConflicts(String repoPath) async {
    final diff = await _run(
      args: ['diff', '--name-only', '--diff-filter=U'],
      workingDirectory: repoPath,
      allowNonZeroExit: true,
    );
    final lines = diff.stdout
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    return lines;
  }

  Future<_RunResult> _run({
    required List<String> args,
    required String workingDirectory,
    bool allowNonZeroExit = false,
  }) async {
    final result = await Process.run(
      gitExecutable,
      args,
      workingDirectory: workingDirectory,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    return _RunResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      allowNonZeroExit: allowNonZeroExit,
    );
  }
}

class _RunResult {
  _RunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.allowNonZeroExit,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool allowNonZeroExit;
}

