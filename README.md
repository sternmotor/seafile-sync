# seafile-sync


Docker image and script to sync all seafile libraries of a given seafile user. This has been build for clear backups with the real files. 

Seafile by itself stores deduplicating, block based but this is bad for recovering single files.

There is no need to find out any repository id from seafile web site. All private reposiroy ids are fetched from seafile server via API call.
