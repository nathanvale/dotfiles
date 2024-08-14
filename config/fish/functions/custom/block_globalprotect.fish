# Function: block_globalprotect
# Description: Blocks GlobalProtect network requests on port 443.
#              Enables pf if not already enabled, adds a rule to block port 443 in pf.conf,
#              reloads pf configuration, kills GlobalProtect if it's running,
#              waits for GlobalProtect to try to reconnect for 20 seconds,
#              unblocks port 443 after GlobalProtect has given up as a VPN.
#
# Usage: block_globalprotect
# To avoid SUDO password prompts, add the following lines to the sudoers file:
# your_username ALL=(ALL) NOPASSWD: /sbin/pfctl
# your_username ALL=(ALL) NOPASSWD: /usr/bin/tee -a /etc/pf.conf
# your_username ALL=(ALL) NOPASSWD: /usr/bin/pkill
# your_username ALL=(ALL) NOPASSWD: /usr/bin/sed




function block_globalprotect --description "Block GlobalProtect network requests"
    # Enable pf if not already enabled
    sudo pfctl -e >/dev/null 2>&1

    echo "Blocking GlobalProtect network requests on port 443..."

    # Block GlobalProtect network requests on port 443
    echo "block drop quick proto tcp from any to any port 443" | sudo tee -a /etc/pf.conf >/dev/null 2>&1

    # Reload pf configuration
    sudo pfctl -f /etc/pf.conf >/dev/null 2>&1

    # Kill GlobalProtect if it's running
    pkill -x GlobalProtect

    echo "GlobalProtect will now try to reconnect as a VPN for 20 seconds before it ultimately gives up."

    # Let GlobalProtect try to reconnect for 20 seconds before it ultimately fails
    sleep 20

    # GlobalProtect has now given up as a VPN so unblock port 443 so other processes can use it
    unblock_globalprotect

    echo "GlobalProtect VPN is now dead and port 443 is now unblocked again."
end
