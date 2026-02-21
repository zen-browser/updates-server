import os

# For branch redirects. E.g. if we want to convert 'alpha' -> 'beta' in all URLs,
# but still maintain the old URLs just in case someone has not updated
# broken branch -> fixed branch
REDIRECTS = {
    "twilightundefined": "twilight", # A bug there was with previous twilight updates
    "alpha": "release", # Alpha -> Beta
    "alpha-generic": "release", # Alpha -> Beta
    "beta-generic": "release", # Beta (Generic) -> Beta
    "twilight-generic": "twilight", # Twilight (Generic) -> Twilight
    "beta": "release", # Beta -> Release
    "release-generic": "release", # Generic release -> release
}

UPDATES_ROOT = "updates/browser"

REPLACE = {
    "/download/twilight/": "/download/twilight-1/"
}

for new, old in REDIRECTS.items():
    print(f"Redirecting {old} -> {new}")
    # just create and copy the content of the old file to the new file
    # the structure of the updates server is updates/browser/<target_build>/<branch>/update.xml
    # we want to replace the branch with the new branch
    for target in os.listdir(UPDATES_ROOT):
        target_path = os.path.join(UPDATES_ROOT, target)
        for branch in os.listdir(target_path):
            if branch == old:
                # The directory doesnt exist, so we create a new one
                new_branch_path = os.path.join(target_path, new)
                old_branch_path = os.path.join(target_path, old)
                os.makedirs(new_branch_path)
                for update in os.listdir(old_branch_path):
                    update_path = os.path.join(old_branch_path, update)
                    with open(update_path, "r") as f:
                        content = f.read()
                        for r, v in REPLACE.items():
                            content = content.replace(r, v)
                        with open(update_path, "w") as f2:
                            f2.write(content)
                        new_update_path = os.path.join(new_branch_path, update)
                        with open(new_update_path, "w") as nf:
                            nf.write(content)
                print(f"Redirected {old} -> {new} in {target}/{branch}")

print("Done! Let's build the site next!")

