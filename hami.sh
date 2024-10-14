#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Function to set up the node
setup_node() {
    print_info "Updating system and installing jq..."
    sudo apt-get update && sudo apt-get install -y jq

    print_info "Creating directory /root/hami..."
    mkdir -p /root/hami
    cd /root/hami || { print_error "Failed to change directory to /root/hami"; exit 1; }

    print_info "Downloading heminetwork..."
    wget --quiet --show-progress https://github.com/hemilabs/heminetwork/releases/download/v0.4.5/heminetwork_v0.4.5_linux_amd64.tar.gz -O heminetwork_v0.4.5_linux_amd64.tar.gz
    if [ $? -ne 0 ]; then
        print_error "Failed to download heminetwork."
        exit 1
    fi

    print_info "Extracting heminetwork..."
    tar -xzf heminetwork_v0.4.5_linux_amd64.tar.gz
    if [ $? -ne 0 ]; then
        print_error "Failed to extract heminetwork."
        exit 1
    fi

    print_info "Changing directory to heminetwork_v0.4.5_linux_amd64..."
    cd heminetwork_v0.4.5_linux_amd64 || { print_error "Failed to change directory to heminetwork_v0.4.5_linux_amd64"; exit 1; }

    print_info "Node setup completed successfully!"

    # Call the node_menu function
    node_menu
    
}


# Function to create a wallet
create_wallet() {
    if [ -f ~/popm-address.json ]; then
        print_info "Aapke paas pehle se wallet hai. Copying to /root/hami..."
        cp ~/popm-address.json /root/hami/
        print_info "Wallet already exists at ~/popm-address.json and has been copied to /root/hami."
    else
        print_info "Creating wallet..."
        ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json
        if [ $? -ne 0 ]; then
            print_error "Failed to create wallet."
            exit 1
        fi
        print_info "Wallet created successfully at ~/popm-address.json"
        
        # Copy the newly created wallet to /root/hami
        cp ~/popm-address.json /root/hami/
        print_info "Wallet created successfully!"
    fi

    # Call the node_menu function
    node_menu
}


# Function to show private key
show_priv_key() {
    if [ -f /root/hami/popm-address.json ]; then
        private_key=$(jq -r '.private_key' /root/hami/popm-address.json)
        ethereum_address=$(jq -r '.ethereum_address' /root/hami/popm-address.json)
        pubkey_hash=$(jq -r '.pubkey_hash' /root/hami/popm-address.json)
         print_info ""
        print_info "Your private key is: $private_key"
        print_info ""
        print_info "Your Eth Address key is: $ethereum_address"
         print_info ""
        print_info "Your Public Hash is: $pubkey_hash"
         print_info ""
    else
        print_error "Wallet file not found at ~/root/hami/popm-address.json."
    fi

    # Call the node_menu function
    node_menu
}



# Function to update service with private key
service_update() {
    if [ -f /root/hami/popm-address.json ]; then
        private_key=$(jq -r '.private_key' /root/hami/popm-address.json)
        print_info "Setting up Hemi service with private key..."

        # Define the service file path
        service_file="/etc/systemd/system/hemid.service"

        # Delete the old service file if it exists
        if [ -f $service_file ]; then
            sudo rm -rf $service_file
            print_info "Old Hemi service file deleted."
        fi

        # Write the new service file
        echo "[Unit]" | sudo tee $service_file
        echo "Description=Hemi testnet pop tx Service" | sudo tee -a $service_file
        echo "After=network.target" | sudo tee -a $service_file
        echo "" | sudo tee -a $service_file
        echo "[Service]" | sudo tee -a $service_file
        echo "WorkingDirectory=/root/hami/heminetwork_v0.4.5_linux_amd64" | sudo tee -a $service_file
        echo "ExecStart=/root/hami/heminetwork_v0.4.5_linux_amd64/popmd" | sudo tee -a $service_file
        echo "Environment=\"POPM_BTC_PRIVKEY=$private_key\"" | sudo tee -a $service_file
        echo "Environment=\"POPM_STATIC_FEE=200\"" | sudo tee -a $service_file
        echo "Environment=\"POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public\"" | sudo tee -a $service_file
        echo "Restart=on-failure" | sudo tee -a $service_file
        echo "" | sudo tee -a $service_file
        echo "[Install]" | sudo tee -a $service_file
        echo "WantedBy=multi-user.target" | sudo tee -a $service_file

        print_info "Hemi service setup complete."
        
        # Reload systemd and start the service
        sudo systemctl daemon-reload
        sudo systemctl enable hemid
        sudo systemctl start hemid
        print_info "Hemi service started successfully."
    else
        print_error "Wallet file not found at /root/hami/popm-address.json. Cannot set up service."
    fi

    # Call the node_menu function
    node_menu
}



# Function to refresh the Hemi node service
refresh_node() {
    print_info "Refreshing the Hemi node service..."

    # Reload systemd configuration
    sudo systemctl daemon-reload
    
    # Enable the hemid service
    sudo systemctl enable hemid.service
    
    # Start (or restart) the hemid service
    sudo systemctl restart hemid.service
    
    print_info "Hemi node service refreshed and restarted successfully."

    # Call the node_menu function
    node_menu
}


# Function to check logs of the Hemi node service
logs_checker() {
    print_info "Checking logs for the Hemi node service..."

    # Display the last 50 logs and follow the log output for hemid.service
    sudo journalctl -u hemid.service -f -n 50

    # Call the node_menu function
    node_menu
}


# Function to display menu and handle user input
node_menu() {
    print_info "====================================="
    print_info "  Hami Node Tool Menu    "
    print_info "====================================="
    print_info ""
    print_info "1. Setup-Node"
    print_info "2. Wallet-Setup"
    print_info "3. Key-Checker"
    print_info "4. Service-Update"
    print_info "5. Refresh-Node"
    print_info "6. Logs-Checker"
    print_info "7. Exit"
    print_info ""
    print_info "==============================="
    print_info " Created By : CryptoBuroMaster "
    print_info "==============================="
    print_info ""  

    # Prompt the user for input
    read -p "Enter your choice (1, - 7): " user_choice
    
    # Handle user input
    case $user_choice in
        1)
            setup_node
            ;;
        2)
            create_wallet
            ;;
        3)
            show_priv_key
            ;;
        4)
            service_update
            ;;
        5)
            refresh_node
            ;;
        6)
            logs_checker
            ;;
        7)
            print_info "Exiting the script. Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice. Please enter 1, 2, or 3."
            node_menu # Re-prompt if invalid input
            ;;
    esac
}

# Call the node_menu function
node_menu







