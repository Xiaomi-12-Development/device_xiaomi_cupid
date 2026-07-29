#!/bin/bash

        echo "=> [INFO] Checking repos."
# Repository list
REPOS=(
    "https://github.com/Xiaomi-12-Development/device_xiaomi_sm8450-common device/xiaomi/sm8450-common 17.0"
    "https://github.com/Xiaomi-12-Development/vendor_xiaomi_sm8450-common vendor/xiaomi/sm8450-common 17.0"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm8450 kernel/xiaomi/sm8450 lineage-23.2"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm8450-modules kernel/xiaomi/sm8450-modules lineage-23.2"
    "https://github.com/LineageOS/android_kernel_xiaomi_sm8450-devicetrees kernel/xiaomi/sm8450-devicetrees lineage-23.2"
    "https://github.com/TheMuppets/proprietary_vendor_xiaomi_cupid vendor/xiaomi/cupid lineage-23.2"
    "https://github.com/Evolution-X-Devices/hardware_xiaomi/ hardware/xiaomi cnb-no-dolby"
    "https://github.com/Evolution-X-Devices/hardware_dolby hardware/dolby cnb-aospa"
)

# Cloning repositories
for item in "${REPOS[@]}"; do
    read -r url target branch <<< "$item"
    
    if [ -d "$target" ]; then
        echo "=> [SKIPPED] $target already exists."
    else
        echo "=> [CLONING] Fetching into $target (Branch: $branch)..."
        git clone "$url" "$target" -b "$branch" || { echo "Clone failed: $target"; exit 1; }
    fi
done

        echo "=> [INFO] Cloning completed."

CONFIG_FILE="kernel/xiaomi/sm8450/arch/arm64/configs/vendor/waipio_GKI.config"
# Directory check for KernelSU-Next
KSU_DIR="kernel/xiaomi/sm8450/KernelSU-Next"

# Directory check
if [ -d "$KSU_DIR" ]; then
    echo "=> [INFO] KernelSU-Next directory detected."
    
    # Update to withKSU if it's the original setting
    if grep -q 'CONFIG_LOCALVERSION="-gki"' "$CONFIG_FILE"; then
        sed -i 's/CONFIG_LOCALVERSION="-gki"/CONFIG_LOCALVERSION="-gki_withKSU"/' "$CONFIG_FILE"
        echo "=> [CONFIG] Updated LOCALVERSION to -gki_withKSU"
    fi
else
    # Prompt the user
    read -p "KernelSU-Next not found. Do you want to install it? (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        pushd kernel/xiaomi/sm8450 > /dev/null
        curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/next/kernel/setup.sh" | bash -
        popd > /dev/null
        
        # Update config after installation
        if grep -q 'CONFIG_LOCALVERSION="-gki"' "$CONFIG_FILE"; then
            sed -i 's/CONFIG_LOCALVERSION="-gki"/CONFIG_LOCALVERSION="-gki_withKSU"/' "$CONFIG_FILE"
            echo "=> [CONFIG] Updated LOCALVERSION to -gki_withKSU"
        fi
    else
        # If user declines, update to withoutKSU
        if grep -q 'CONFIG_LOCALVERSION="-gki"' "$CONFIG_FILE"; then
            sed -i 's/CONFIG_LOCALVERSION="-gki"/CONFIG_LOCALVERSION="-gki_withoutKSU"/' "$CONFIG_FILE"
            echo "=> [CONFIG] Updated LOCALVERSION to -gki_withoutKSU"
        fi
        echo "=> [INFO] Installation skipped."
    fi
fi

CONFIG_FILE="kernel/xiaomi/sm8450/arch/arm64/configs/vendor/waipio_GKI.config"

if ! grep -q "CONFIG_LOCALVERSION_AUTO" "$CONFIG_FILE"; then
    echo "=> [INFO] Adding LOCALVERSION_AUTO to config."
    echo "# CONFIG_LOCALVERSION_AUTO is not set" >> "$CONFIG_FILE"
else
    echo "=> [INFO] LOCALVERSION_AUTO setting already exists, skipping."
fi