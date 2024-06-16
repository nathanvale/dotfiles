
# Yabai LaunchAgent Setup Guide

To run the `sudo yabai --load-sa` command on startup with the necessary superuser privileges, you can create a LaunchAgent that uses a `sudo` command. This involves setting up `sudo` to allow the command to run without requiring a password. Here’s how you can achieve this:

## Step 1: Create a Sudoers File for No Password Requirement

First, you need to create a sudoers file that allows the `sudo yabai --load-sa` command to run without a password.

1. Open a terminal.
2. Edit the sudoers file using `visudo`:
   ```sh
   sudo visudo -f /etc/sudoers.d/yabai
   ```
3. Add the following line (replace `your_username` with your actual username):
   ```sh
   your_username ALL=(ALL) NOPASSWD: /usr/local/bin/yabai --load-sa
   ```

## Step 2: Create a LaunchAgent

Next, create a LaunchAgent that runs the command on startup.

1. Create a new plist file in `~/Library/LaunchAgents/`:
   ```sh
   nano ~/Library/LaunchAgents/com.yabai.loadsa.plist
   ```
2. Add the following content to the plist file:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.yabai.loadsa</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/bin/sudo</string>
           <string>/usr/local/bin/yabai</string>
           <string>--load-sa</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
   </dict>
   </plist>
   ```
3. Save the file and exit.

## Step 3: Load the LaunchAgent

Finally, load the LaunchAgent to ensure it starts on login.

1. Load the LaunchAgent:
   ```sh
   launchctl load ~/Library/LaunchAgents/com.yabai.loadsa.plist
   ```

## Troubleshooting Repeated Execution Issues

It sounds like the LaunchAgent might be configured incorrectly, causing it to repeatedly attempt to execute and show notifications. Let's troubleshoot and correct this.

### Modify the LaunchAgent to Prevent Repeated Execution

We need to ensure that the LaunchAgent does not continuously try to run the command. This can be achieved by removing the `KeepAlive` key, which is likely causing it to rerun repeatedly.

1. Open the Terminal and edit the plist file:
   ```sh
   nano ~/Library/LaunchAgents/com.yabai.loadsa.plist
   ```
2. Modify the content to remove the `KeepAlive` key. The updated content should look like this:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.yabai.loadsa</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/bin/sudo</string>
           <string>/usr/local/bin/yabai</string>
           <string>--load-sa</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
   </dict>
   </plist>
   ```
3. Save the file and exit `nano`:
   - Press `Ctrl+X`, then `Y` to confirm saving, and press `Enter`.

### Unload and Reload the LaunchAgent

1. Unload the current LaunchAgent:
   ```sh
   launchctl unload ~/Library/LaunchAgents/com.yabai.loadsa.plist
   ```
2. Reload the modified LaunchAgent:
   ```sh
   launchctl load ~/Library/LaunchAgents/com.yabai.loadsa.plist
   ```

### Verify the Execution

To ensure the command is executed correctly and does not show repeated notifications:

1. Open a new Terminal window and manually test the `sudo yabai --load-sa` command:
   ```sh
   sudo yabai --load-sa
   ```
2. If the command runs successfully without issues, reboot your system to test the LaunchAgent.

### Optional: Check Logs for Errors

If issues persist, check the system logs for more details on why the LaunchAgent might be running repeatedly or failing:

1. Open the Console application (found in Applications > Utilities > Console).
2. Look for logs related to `yabai` or `com.yabai.loadsa`.

These steps should help ensure that the LaunchAgent runs the `sudo yabai --load-sa` command on startup without causing repeated notifications or re-execution.
