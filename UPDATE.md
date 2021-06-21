# Creating an Update

*It is recommended to integrate any updates into the pi-gen creation scripts during the next summer before the next year's image is created.*

- Create a task file in `updates/` called `{your_version}.yaml` (e.g. `3.0.0.yaml`)
*(Note that it has to be `.yaml`, not `.yml`, otherwise it won't be found)*
- Include all tasks in this file
- Update the version (see below)


## Adding Pre-made Files

- Create a directory in `files/` called `{your_version}` (e.g. `files/3.0.0`)
- Add a task that uses the copy module:
```
- name: Add {your_file}
  become: yes
  copy:
    src: files/{your_version}/{your_file}
    dest: {destination_path}/{your_file}
```

### Adding an Update to `hd-image.bash` or `PiTracker.bash`

- Make a copy of the latest version of the file and add it to `files/{your_version}/`
  - Check that no versions since have made single line updates to the file (using `lineinfile` or `replace`, for example). If so, then you should probably get the file from an updated copy of the image.
- Make any necessary updates to that file
- There are pre-made tasks that you can use:
```
- name: Update PiTracker
  import_tasks: ../update_pitracker.yaml
  vars:
    version: 'your_version'
```
```
- name: Update hd-image
  import_tasks: ../update_hd-image.yaml
  vars:
    version: 'your_version'
```


## Updating the Version

- There is a pre-made task that is used to update the version:
```
- name: Update Version
  import_tasks: ../update_version.yaml
  vars:
    version: 'your_version'
```


## A Note About Version Numbering

Before 2.0.3, versions were sorted as strings, meaning 2.0.9 would come after 2.0.10.
This has been fixed with the custom `version_sort` filter (in `filter_plugins/VersionSort.py`) and 2.0.9 will come before 2.0.10, as intended.
