# hamster-qml
=============
QML GUI frontend for the [hamster-lib](https://github.com/projecthamster/hamster-lib) timetracking backend.

This GUI front-end is the result of not finding a suitable replacement for the [Project Hamster](https://projecthamster.wordpress.com/about/) application on Windows. 
The [hamster-cli](https://github.com/projecthamster/hamster-cli) Command Line Interface was used for a while until this project was started. 

This project has no connection with the [Project Hamster](https://github.com/projecthamster) except for using the Python library provided by the project. 

Tools used
----------
Since the hamster-lib is written in Python, Python was chosen as the language for the development. 
QML was chosen as a learning opportunity to get familiar with QML and QtQuick.

I have a strong C++ and Qt background but basically no experiance with QML nor Python.
This whole project is seen as a learning opportunity but will hopefully be useful to some people. 

Running the GUI
===============
Since the GUI is based on Python and QML there is no need to build the sources. All that is needed is to install the correct software, get the source and run the application.
Although all development and testing is done in Windows, there is no reason why it should not work on other *proper* Operating Systems. 

The following steps can be used to run the GUI:

1. Install Python 3.6.
  * When installing on Windows, make sure Python is installed in a place where there is no spaces in the path.
    For example, `C:\Progam Files\` should not be used. This is to prevent issues with Python in future.
  * Development was done on the 32-bit version of Python.
1. Install the hamster-lib inside Python.
  * `pip install hamster-lib`
  * Version 0.12 was latest and used for the development.
1. Install PyQt 5.
  * `pip install PyQt5`
1. Get the hamster-QML sources
  * Download or check out the sources from this project page.
1. Run the application.
  * From the source folder: `python hamster-qml.py`
  
Using the application
=====================

Terms
-----
The following terms are used in the application, they originate from the terms used by the hamster-lib.

| Term        | Description |
|-------------|-------------|
| **Fact**         | Event or work that is getting done. It has a start and end time, a category, activity and description. |
| **Category**     | Category is the high level grouping that the work belongs to. For example this project, `hamster-qml` can be one. |
| **Activity**     | Activity is like a subtask of the category, like `develop` or `test` |
| **Description**  | The description can be a comment describing the work done. For example `fixing some issue`. |
| **Ongoing Fact** | Work or a fact that is currenlty in progress, it does not have an end time (yet). |

Logging work
------------
To log work, or a new fact, the activity must be entered in the 'Log work' edit field. The following format is required:

```<time> [activity]@<category>, description```

| Tag | Required | Comment |
|-----|----------|---------|
| `<time>`      | false | Time that the work started. Either one of the following formats are required.
|               |       | `HH:MM` - Absolute start time of the task, example: `08:00`
|               |       | `HH:MM - HH:MM` - Absolute start and end time, example: `08:00 - 09:00`
|               |       | `-MM` - Start time relative to the current time, example: `-30` (started 30 minutes ago). 
|               |       | No time if the task starts at the current time, now. 
| `[activity]`  | false | Any word without whitespace or special characters, example: `development` 
|               |       | If no activity is specified, do not add the `@`-character. 
| `<category>`  | true  | Any word without whitespace or special characters, example: `hamster`.
| `description` | false | Short description of the activity if needed.
|               |       | If no description is supplied, do not add the `,`-character. 

If a fact is started without an end time, the work will be regarded as ongoing. 
As such it will be added to the 'Current work' edit field. This work can then be stopped or cancelled. 
If stopped, the current time will be used for the end time of the work. If the work is cancelled, it will be removed and deleted. 
Ongoing work will be remembered between application runs, for example when restarting the computer. 

New work can be adde even though there is an active fact. When this happens, the current work will be stopped and the new work will be started. 
The end time of the work will be set to the start time of the new work. 

Updating work
-------------
On any of the tables showing logged work, one can double click on an entry to edit the work. 