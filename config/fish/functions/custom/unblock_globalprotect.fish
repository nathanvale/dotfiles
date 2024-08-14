# Function: unblock_globalprotect
# Description: Unblock GlobalProtect network requests on port 443.
#
# This function removes the block rule for GlobalProtect in the pf configuration file.
# It then reloads the pf configuration to apply the changes.
# Optionally, it can also disable pf if it was not previously enabled.
#
# Usage: unblock_globalprotect
#
# Example:
#   unblock_globalprotect
#
#   This will unblock GlobalProtect network requests.
#
function unblock_globalprotect --description "Unblock GlobalProtect network requests"
    # Path to pf configuration file
    set PF_CONF /etc/pf.conf >/dev/null 2>&1

    # Remove the block rule for GlobalProtect
    sudo sed -i.bak '/block drop quick proto tcp from any to any port 443/d' $PF_CONF >/dev/null 2>&1

    # Reload pf configuration
    sudo pfctl -f $PF_CONF >/dev/null 2>&1

    # Optionally, disable pf if it was not previously enabled
    # sudo pfctl -d

end
