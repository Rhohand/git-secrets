# TODO place in readme
# TO SETUP SSH ON WINDOWS
##### GIT GUI > HELP > SHOW SSH KEYS
#### ADD THESE KEYS TO BITBUCKET | GITHUB -> Your profile -> auth -> SSH
# IF you want this to load automagically change your profile https://www.howtogeek.com/50236/customizing-your-powershell-profile/
# Test-Path $profile
# New-Item -path $profile -type file force

function GitSecrects() { 
    param(
# TODO
# git secrets --scan [-r|--recursive] [--cached] [--no-index] [--untracked] [<files>...]
# git secrets --scan-history
# git secrets --install [-f|--force] [<target-directory>]
# git secrets --list [--global]
# git secrets --add [-a|--allowed] [-l|--literal] [--global] <pattern>
# git secrets --add-provider [--global] <command> [arguments...]
# git secrets --register-aws [--global]
# git secrets --aws-provider [<credentials-file>]
    )
}

function DotNetSecrectsScanner() { 
    # https://www.hanselman.com/blog/BestPracticesForPrivateConfigDataAndConnectionStringsInConfigurationInASPNETAndAzure.aspx
    # https://docs.microsoft.com/en-us/aspnet/identity/overview/features-api/best-practices-for-deploying-passwords-and-other-sensitive-data-to-aspnet-and-azure 
    # TODO *.config 
    # TODO *.azure.*
    # TODO *.azure.*devops*
    # TODO filter out . directory ?
}

function GitMergeSimple() {
    param(
        [string] $TargetBranchName,
        [string] $SourceBranchName = 'master',
        [switch] $Push,
        [switch] $verbose
    )
    GitCheckout -branch $TargetBranchName
    GitMerge -BranchName $SourceBranchName -RemoteBranch -Push:$Push -verbose:$verbose
}
function GitCheckout() {

    param(
        $branch = 'master',
        [switch] $new,
        [switch] $force 
    )

    # if( $partTwo) {
    #     # TODO
    #     $currentBranchName = (git rev-parse --abbrev-ref HEAD)

    #     $branch = ""
        
    #     $branchParts = $currentBranchName.Split('-')[2]
    # }
    if($force) {
        git branch -D $branch
    }
    if($new) {
        git checkout -b $branch
    } else {
        git checkout $branch
    }
    git pull
}
function BitbucketMergeAfterBuild() {

    # Annoying that pr only shows on a push with commits for bamboo
    $result = git push
    Write $result 
    $result | ? { $_ -match 'pull-requests' } {
        write 'sleeping till build has been finished'
        sleep -seconds (60 * 15) # 10 + 5 min buffer - Note: depends on the project

        write "pr ready"
        write $_
    }
}
function GitStatus() {
    param(
        [switch] $short,
        [switch] $branch,
        [string] $branchName,
        [switch] $showStash,
        [switch] $unTrackedFiles,
        [string] $unTrackedFilesType,
        [switch] $ignored,
        [string] $ignoredType
    )
    $gitArgs =   @('status')

    if( $short )              { $gitArgs = '--short' }
    if( $branch  )  { $gitArgs += "--branch $branchName" }
    if( $showStash  )  { $gitArgs += "--show-stash" }
    if( $unTrackedFiles  )  { $gitArgs += "--untracked-files=$unTrackedFilesType" } # no normal all
    if( $ignored  )  { $gitArgs += "--untracked-files=$ignoredType" } # traditional no matching
    if($verbose) { write $gitArgs }

    & git $gitArgs
}

function GitMerge() {
    param(
        [switch] $Commit,
        [switch] $NoCommit,
        [switch] $Edit,
        #[switch] $NoEdit, implicit for now
        [switch] $Stat,
        [switch] $NoStat,
        [switch] $Squash,
        [string] $Message,
        [string] $BranchName,
        [switch] $RemoteBranch,
        [switch] $Push,
        [switch] $Continue,
        [switch] $verbose
    )
    $gitArgs =   @('merge', $BranchName)
    if( $RemoteBranch) {  $gitArgs =   @('merge', "origin/$BranchName")}
    if( $Message) {  $gitArgs +=    @('-m' , $Message)}


if($Commit)      { $gitArgs += "-commit"}
if($NoCommit)    { $gitArgs += "--no-commit"}
if($Edit)        { $gitArgs += "--edit"}
if($Stat)        { $gitArgs += "--stat"}
if($NoStat)        { $gitArgs += "--no-stat"}
if($Squash)      { $gitArgs += "--squash"}

if($Continue ) { $gitArgs =   @('merge','--continue') }

    if($verbose) { write $gitArgs }

    & git $gitArgs

    if($Push ){ git push }
}

function GitStash() {
    param(
        [switch] $Push,
        [switch] $Pop,
        [switch] $Drop,
        [switch] $List,
        [string] $Branch,
        [string] $BranchName,
        [switch] $Clear,
        [switch] $Create,
        [string] $CreateMessage,
        [string] $Store,
        [string] $StoreMessage
    )

if( $Push) {  $gitArgs =   @('stash' , 'push')}
if( $Pop) {  $gitArgs =    @('stash' , 'pop')}
if( $Drop) {  $gitArgs =   @('stash' , 'drop')}
if( $List) {  $gitArgs =   @('stash' , 'list')}
if( $Branch) {  $gitArgs = @('stash' , 'branch', "$BranchName")}
if( $Clear) {  $gitArgs =  @('stash' , 'clear')}
if( $Create) {  $gitArgs = @('stash' , 'create', "$CreateMessage")}
if( $Store) {  $gitArgs = @( 'stash' , 'store', "-m $StoreMessage")}


    if( $Path )              { $gitArgs = 'remote' + $gitArgs  }
    if( $NumberOfCommits  )  { $gitArgs += "-n $NumberOfCommits" }
    if( $Format  )  { $gitArgs += "--format=$Format" } #oneline, short, medium, full, fuller, email, raw, format:<string> and tformat:<string>
    if( $Pretty  )  { $gitArgs += "--format=$Format" } #oneline, short, medium, full, fuller, email, raw, format:<string> and tformat:<string>
    if($verbose) { write $gitArgs }

    & git $gitArgs
}

function GitPushChangesAndTags() {
    param(
        [switch] $Tags,
        [switch] $Force,
        [switch] $verbose
    )
    GitPush        -force:$force -verbose:$verbose
    GitPush -Tags  -force:$force -verbose:$verbose
}
function GitPush() {
    param(
        [switch] $RemotePrune,
        [switch] $Tags,
        [switch] $Force,
        [switch] $verbose
    )
    $gitArgs =   @('push')

    # Incredibly dangerous as it will prune remotes
    if($RemotePrune) { Write-Warning 'Adv git commands not enabled'}
    # if($RemotePrune) {$gitArgs += '--prune'}
    if($Tags) {$gitArgs += '--follow-tags'}
    if($Force) {$gitArgs += '--force-with-lease'}
    if($verbose) {$gitArgs += '--verbose'}
    
    & git $gitArgs

    git push
    # It's possible to se the remote pull request from the output $result | ? { $_ -match 'pull-requests' } {
}

# need to use Global https://stackoverflow.com/questions/12535419/setting-a-global-powershell-variable-from-a-function-where-the-global-variable-n
function GitPushBranch() {
    param(
        [string] $branch,
        [switch] $new,
        [switch] $stash,
        [switch] $stashWip,
        [switch] $force
    )

    if($Global:branchesStack -and $Global:branchesStack.gettype().name -match 'stack') {

    } else {
        $Global:branchesStack = new-object system.collections.stack
    }

    $currentBranchName = (git rev-parse --abbrev-ref HEAD)

    if($stash) {
        GitStash -Push
    }
    if($stashWip) {
        Git
    }

    $Global:branchesStack.Push($currentBranchName)

    GitCheckout -branch $branch -new:$new -force:$force
}

function GitPopBranch() {
    param(
        [switch] $new,
        [switch] $force
    )
    if($Global:branchesStack) {
       $branch =  $Global:branchesStack.Pop()
       GitCheckout -branch $branch -new:$new -force:$force
    }
}

function GitLog() {
    param(
        [string] $Path,
        [int]    $NumberOfCommits,
        [string] $Format,
        [string] $Pretty,
        [switch] $verbose
    )

    $gitArgs = $gitArgs = @('log')
    if( $Path )              { $gitArgs = 'remote' + $gitArgs  }
    if( $NumberOfCommits  )  { $gitArgs += "-n $NumberOfCommits" }
    if( $Format  )  { $gitArgs += "--format=$Format" } #oneline, short, medium, full, fuller, email, raw, format:<string> and tformat:<string>
    if( $Pretty  )  { $gitArgs += "--format=$Format" } #oneline, short, medium, full, fuller, email, raw, format:<string> and tformat:<string>
    if($verbose) { write $gitArgs }

        & git $gitArgs
}

function GitCommit() { 
    param(
        [string] $message,
        [switch] $add,
        [switch] $ignoreTags,
        [switch] $all,
        [switch] $wip
    )
    if($wip) {
        $currentBranchName = (git rev-parse --abbrev-ref HEAD)
        GitCheckout -branch "$currentBranchName-wip" -new
    }
    if($add) {
        if($all) {
            git add --all
        }else {
            git add .
        }
    }
    git commit -m $message
}


function GitCommitAndPush() {
    param(
        [string] $message,
        [switch] $add,
        [switch] $force,
        [switch] $ignoreTags,
        [switch] $all,
        [switch] $skipPush,
        [switch] $wip
    )
    GitCommit  -message $message -add:$add -ignoreTags:$ignoreTags -all:$all -wip:$wip

    if($skipPush) { 
    } else {
        GitPush -Force:$Force -verbose:$verbose    
        if($ignoreTags) {
        } else {
            GitPush -Force:$Force -verbose:$verbose    -tags:$Tags
        }
    }
}

function CreateNewBranch() {
    param(
        $newBranch = 'feature/my-random-feature-branch',
        $parentBranch = 'master',
        [string[]] $parentBranches,
        [string[]] $paths ,
        [switch] $verbose
    )

    if($paths -and $paths.Count -gt 0) {
        if($verbose) { write $paths }
        $i = 0
        $paths | % {
           if($verbose) { write "i $i" }

            $path = $_
            pushd $path
                $parentBranch = $parentBranches[$i]
                if($verbose) { write "parentBranch $parentBranch" }
                GitCheckout -branch $parentBranch
                GitCheckout -branch $newBranch -new -force
                git push --set-upstream origin $newBranch
            popd
            $i++
        }
        if($verbose) {
            $paths | % {
                $path = $_
                pushd $path
                    write "path $path"
                    git status
                popd
            }
        }

    } else {
        GitCheckout -branch $parentBranch
        GitCheckout -branch $newBranch -new
        git push --set-upstream origin $newBranch
    }
}


function CreateNewBranches(){
    param(
        $newBranch = 'feature/my-random-feature-branch',
        $parentBranch = 'master',
        [string[]] $parentBranches = @('master', 'develop', 'develop'),
        [string[]] $paths = @('proj1', 'proj2', 'proj3', 'proj4'),
        [switch] $verbose
    )
    if($verbose) {
        Write "CreateNewBranch -newBranch $newBranch  -paths $paths"
        Write '-parentBranch '
        Write $parentBranch
        CreateNewBranch -newBranch $newBranch -parentBranches $parentBranches -paths $paths -verbose
    } else {
        CreateNewBranch -newBranch $newBranch -parentBranches $parentBranches -paths $paths
    }
}

function GitResetBranch() {
    param(
        $branch = 'master',
        $parentBranch = 'master',
        $wipBranch = '{0}-wip'
    )
# TODO Test this
    git checkout $branch
    git fetch
    $wipBranch = $wipBranch -f $branch
    git branch -D $wipBranch
    git checkout $wipBranch
    git checkout $parentBranch
    git branch -D $branch
    git fetch
    git checkout $branch
}

function GitAdd() { 
    param(
        [string] $FileRegex = '.',
        [switch] $DryRun,
# Be verbose.
        [switch] $Verbose,
# Allow adding otherwise ignored files.
        [switch] $Force
# TODO 
# -i--interactive
# Add modified contents in the working tree interactively to the index. Optional path arguments may be supplied to limit operation to a subset of the working tree. See “Interactive mode” for details.
# -p--patch
# Interactively choose hunks of patch between the index and the work tree and add them to the index. This gives the user a chance to review the difference before adding modified contents to the index.


# This effectively runs add --interactive, but bypasses the initial command menu and directly jumps to the patch subcommand. See “Interactive mode” for details.
# -e--edit
# Open the diff vs. the index in an editor and let the user edit it. After the editor was closed, adjust the hunk headers and apply the patch to the index.


# The intent of this option is to pick and choose lines of the patch to apply, or even to modify the contents of lines to be staged. This can be quicker and more flexible than using the interactive hunk selector. However, it is easy to confuse oneself and create a patch that does not apply to the index. See EDITING PATCHES below.
# -u--update
# Update the index just where it already has an entry matching <pathspec>. This removes as well as modifies index entries to match the working tree, but adds no new files.


# If no <pathspec> is given when -u option is used, all tracked files in the entire working tree are updated (old versions of Git used to limit the update to the current directory and its subdirectories).
# -A--all--no-ignore-removal
# Update the index not only where the working tree has a file matching <pathspec> but also where the index already has an entry. This adds, modifies, and removes index entries to match the working tree.


# If no <pathspec> is given when -A option is used, all files in the entire working tree are updated (old versions of Git used to limit the update to the current directory and its subdirectories).
# --no-all--ignore-removal
# Update the index by adding new files that are unknown to the index and files modified in the working tree, but ignore files that have been removed from the working tree. This option is a no-op when no <pathspec> is used.


# This option is primarily to help users who are used to older versions of Git, whose "git add <pathspec>…?" was a synonym for "git add --no-all <pathspec>…?", i.e. ignored removed files.
# -N--intent-to-add
# Record only the fact that the path will be added later. An entry for the path is placed in the index with no content. This is useful for, among other things, showing the unstaged content of such files with git diff and committing them with git commit -a.
# --refresh
# Don’t add the file(s), but only refresh their stat() information in the index.
# --ignore-errors
# If some files could not be added because of errors indexing them, do not abort the operation, but continue adding the others. The command shall still exit with non-zero status. The configuration variable add.ignoreErrors can be set to true to make this the default behaviour.
# --ignore-missing
# This option can only be used together with --dry-run. By using this option the user can check if any of the given files would be ignored, no matter if they are already present in the work tree or not.
# --no-warn-embedded-repo
# By default, git add will warn when adding an embedded repository to the index without using git submodule add to create an entry in .gitmodules. This option will suppress the warning (e.g., if you are manually performing operations on submodules).
# --renormalize
# Apply the "clean" process freshly to all tracked files to forcibly add them again to the index. This is useful after changing core.autocrlf configuration or the text attribute in order to correct files added with wrong CRLF/LF line endings. This option implies -u.
# --chmod=(+|-)x
# Override the executable bit of the added files. The executable bit is only changed in the index, the files on disk are left unchanged.

    )
    $gitArgs = @('add')
    if([string]::IsNullOrWhiteSpace($FileRegex)) {
        Write-Error "File Regex cannot be empty"
    } else {
        $gitArgs += "$FileRegex"
    } 
    if($DryRun){ $gitArgs += "--dry-run"}
    if($Force){ $gitArgs += "--force"}
    if($verbose){ $gitArgs += "--verbose"}
    & git $gitArgs 
}

function GitPull() {
    param(
        $repoName,
        [switch] $verbose,
        [string] $rebaseType # false true preserve interactive
    )
    pushd $repoName
        $gitArgs = @('pull')
        if([string]::IsNullOrWhiteSpace($rebaseType)) {
            $gitArgs += "--rebase=$rebaseType"
        } 
        if($verbose){ $gitArgs += "--verbose"}
        & git $gitArgs 
    popd 
}

function GitPulls() {
    @('proj1', 'proj2', 'proj3', 'proj4') | % {
        $repoName = $_
        if(!(Test-Path -Path $repoName -ErrorAction SilentlyContinue)) {
            Write-Warning "Skipping $repoName as folder does not exist"
        } else {
            # git fetch 
            Write $repoName
            GitPull -repoName $repoName
        }
    }
}

function GitClones() {
    @('proj1', 'proj2', 'proj3', 'proj4') | % {
        $repoName = $_
        if(Test-Path -Path $repoName -ErrorAction SilentlyContinue) {
            Write-Warning "Skipping $repoName as folder already exists"
        } else {
            GitClone -repoName $repoName -ssh
        }
    }
}

function GitClonesCurrent() {
    GitClones
    @('proj1:master', 'proj2:develop', 'proj3:develop', 'proj4:develop') | % {
        $repoParts= $_.split(':')
        $repoName = $repoParts[0]
        $branchName = $repoParts[1]
        if(Test-Path -Path $repoName -ErrorAction SilentlyContinue) {
            pushd $repoName
                GitCheckout -branch $branchName
            popd
        } else {
            Write-Warning "Skipping $repoName as folder doesn't exist"
        }
    }
}

function GitClone() {
    param(
        [string] $repoName,
        [string] $user,
        [switch] $ssh
    )

    switch($repoName) {
        'proj1' {
            if($ssh) {
                git clone 'ssh://YOUR_GIT_HOST'
            } else {
                git clone 'http://{0}@YOUR_GIT_HOST' -f $user
            }
        }
    }

}


function CheckBranchTagged() {
    param(
        $branch = 'master'
    )

    GitCheckout -branch $parentBranch
    git fetch
    git describe
}

function GitPrune() {
    param(         #
        [switch] $dryRun,         #Do not remove anything; just report what it would remove.
        [switch] $verbose,         #Report all removed objects.
        [switch] $progress,         #Show progress.
        [switch] $expireTime,         #Only expire loose objects older than
        [string] $head,                   #In addition to objects reachable from any of our references, keep objects reachable from listed <head>s.
        [string] $time,
        [string] $headSha,
        [switch] $remote
    )

    $gitArgs = @('prune', '--dry-run')
    if(! $dryRun     ) { $gitArgs = @('prune') }

    if( $remote )      { $gitArgs = 'remote' + $gitArgs  }
    if( $verbose    )  { $gitArgs += '--verbose' }
    if( $progress   )  { $gitArgs += '--progress' }
    if( $expireTime )  { $gitArgs += "--expire  $time" }
    if( $head       )  { $gitArgs += "--head  $headSha" }
    & git $gitArgs
}

function GitPruneAll() {
    # https://stackoverflow.com/questions/20106712/what-are-the-differences-between-git-remote-prune-git-prune-git-fetch-prune
    # There are potentially three versions of every remote branch:
    # 1. The actual branch on the remote repository
    # 2. Your snapshot of that branch locally (stored under refs/remotes/...)
      # git remote prune origin
      # OR
      # git fetch --prune
    # 3. And a local branch that might be tracking the remote branch
      # git branch -d (or -D if it's not merged anywhere).

    # Really, git prune is a way to delete data that has accumulated in Git but is not being referenced by anything.
    #  In general, it doesn't affect your view of any branches.
    # TODO
}

function TagBranch() {
    param(
        $branch = 'master',
        $tag = '0.0.0-alpha-0000',
        [switch] $push,
        [switch] $force

    )

    GitCheckout -branch $parentBranch
    git fetch
    git describe
    git tag -am 'Manual Override'
    if($force)  {
        git push --force-with-lease
    }
    if($push)  {
        git push --follow-tags
    }
}