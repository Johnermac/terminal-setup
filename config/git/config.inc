[core]
	pager = delta

[interactive]
	diffFilter = delta --color-only

[delta]
	navigate = true
	line-numbers = true
	hyperlinks = false

[diff]
	colorMoved = default
	algorithm = histogram

[merge]
	conflictStyle = zdiff3

[rerere]
	enabled = true

[fetch]
	prune = true

[push]
	autoSetupRemote = true

[init]
	defaultBranch = main
