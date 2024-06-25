function unblock_globalprotect --description "Unblock GlobalProtect network requests"
    # Path to pf configuration file
    set PF_CONF /etc/pf.conf

    # Remove the block rule for GlobalProtect
    sudo sed -i.bak '/block drop quick proto tcp from any to any port 443/d' $PF_CONF

    # Reload pf configuration
    sudo pfctl -f $PF_CONF

    # Optionally, disable pf if it was not previously enabled
    # sudo pfctl -d

    echo "GlobalProtect network requests are now unblocked."
end
