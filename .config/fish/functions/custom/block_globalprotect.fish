function block_globalprotect --description "Block GlobalProtect network requests"

    # Enable pf if not already enabled
    sudo pfctl -e

    # Block GlobalProtect network requests on port 443
    echo "block drop quick proto tcp from any to any port 443" | sudo tee -a /etc/pf.conf

    # Reload pf configuration
    sudo pfctl -f /etc/pf.conf

    # Kill GlobalProtect if it's running
    pkill -x "GlobalProtect"

    echo "GlobalProtect network requests are now blocked."
end