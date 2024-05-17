#!/bin/bash

# Menampilkan pesan informasi
echo '================================================================================================================'
echo 'Order VPS garansi 30 hari dan Jasa Installasi Node WA : 081-214-827-906. Atau ke FB : Mochamad Dwi Syafriadi'
echo '================================================================================================================'
echo  # Baris kosong
sleep 5

# Pindah ke direktori home
cd $HOME

# Update daftar paket dan install beberapa paket yang diperlukan
sudo apt update
sudo apt install -y make unzip clang pkg-config lz4 libssl-dev build-essential git jq ncdu bsdmainutils htop gh

# Menampilkan pesan installasi Go dengan background hijau
echo -e '\n\e[42mInstall Go\e[0m\n' && sleep 1
echo  # Baris kosong

cd $HOME
VER="1.22.3"
wget "https://golang.org/dl/go$VER.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$VER.linux-amd64.tar.gz"
rm "go$VER.linux-amd64.tar.gz"
[ ! -f ~/.bash_profile ] && touch ~/.bash_profile
echo "export PATH=$PATH:/usr/local/go/bin:~/go/bin" >> ~/.bash_profile
source $HOME/.bash_profile
[ ! -d ~/go/bin ] && mkdir -p ~/go/bin
echo  # Baris kosong

echo -e '\n\e[42mBuild Apps\e[0m\n' && sleep 1
echo  # Baris kosong

# set vars
echo "export WALLET=\"wallet\"" >> $HOME/.bash_profile

# Meminta pengguna untuk memasukkan moniker
read -p "Masukkan nama validator yang diinginkan (contoh: dwi): " MONIKER
echo "export MONIKER=\"$MONIKER\"" >> $HOME/.bash_profile

echo "export INITIA_CHAIN_ID=\"initiation-1\"" >> $HOME/.bash_profile
echo "export INITIA_PORT=\"51\"" >> $HOME/.bash_profile
source $HOME/.bash_profile

# download binary
cd $HOME
rm -rf initia
git clone https://github.com/initia-labs/initia.git
cd initia
git checkout v0.2.14
make install

# config and init app
initiad init $MONIKER
sed -i -e "s|^node *=.*|node = \"tcp://localhost:${INITIA_PORT}657\"|" $HOME/.initia/config/client.toml

# download genesis and addrbook
wget -O $HOME/.initia/config/genesis.json https://testnet-files.itrocket.net/initia/genesis.json
wget -O $HOME/.initia/config/addrbook.json https://testnet-files.itrocket.net/initia/addrbook.json

# set seeds and peers
SEEDS="cd69bcb00a6ecc1ba2b4a3465de4d4dd3e0a3db1@initia-testnet-seed.itrocket.net:51656"
PEERS="aee7083ab11910ba3f1b8126d1b3728f13f54943@initia-testnet-peer.itrocket.net:11656,9f0ae0790fae9a2d327d8d6fe767b73eb8aa5c48@176.126.87.65:22656,8db26137b760df77c181b939100cdc5ec37c6879@84.46.242.223:15656,b3b7823b530d47848e8f4d2f0cd2020b334bb001@161.97.139.248:16656,1d7d2d2cdb62df2a59aae536047d17f554e58bc3@154.38.181.13:656,1b0843bb3dce9c91115906305b698dc507bf138e@89.117.51.191:51656,0d4614be2f84bfa14177f921ee5733309bccfdef@45.55.202.42:26656,10a824302ce60fca82f71595a9a3227d7cd852a1@38.242.138.185:26656,ab948b87097b6474663e0132ac7360676f7030cd@62.169.26.15:26656,49da32b984143181ae5cae6564aba3a150624d7d@194.180.176.225:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.initia/config/config.toml

# set custom ports in app.toml
sed -i.bak -e "s%:1317%:${INITIA_PORT}317%g;
s%:8080%:${INITIA_PORT}080%g;
s%:9090%:${INITIA_PORT}090%g;
s%:9091%:${INITIA_PORT}091%g;
s%:8545%:${INITIA_PORT}545%g;
s%:8546%:${INITIA_PORT}546%g;
s%:6065%:${INITIA_PORT}065%g" $HOME/.initia/config/app.toml

# set custom ports in config.toml file
sed -i.bak -e "s%:26658%:${INITIA_PORT}658%g;
s%:26657%:${INITIA_PORT}657%g;
s%:6060%:${INITIA_PORT}060%g;
s%:26656%:${INITIA_PORT}656%g;
s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):${INITIA_PORT}656\"%;
s%:26660%:${INITIA_PORT}660%g" $HOME/.initia/config/config.toml

# config pruning
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.initia/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.initia/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"50\"/" $HOME/.initia/config/app.toml

# set minimum gas price, enable prometheus and disable indexing
sed -i 's|minimum-gas-prices =.*|minimum-gas-prices = "0.15uinit,0.01usdc"|g' $HOME/.initia/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.initia/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.initia/config/config.toml

# create service file
sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=Initia node
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.initia
ExecStart=$(which initiad) start --home $HOME/.initia
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# reset and download snapshot
#initiad tendermint unsafe-reset-all --home $HOME/.initia
#if curl -s --head curl https://testnet-files.itrocket.net/initia/snap_initia.tar.lz4 | head -n 1 | grep "200" > /dev/null; then
# curl https://testnet-files.itrocket.net/initia/snap_initia.tar.lz4 | lz4 -dc - | tar -xf - -C $HOME/.initia
#else
#  echo "No snapshot available."
#fi

echo -e '\n\e[42mBuild Cek Sync\e[0m\n' && sleep 1
cd $HOME
echo  # Baris kosong

# Buat file cek-synch.sh dan isi dengan konten yang diberikan
cat << 'EOF' > cek-synch.sh
# Menjalankan perintah untuk mendapatkan informasi sinkronisasi
sync_info=$(initiad status | jq -r .sync_info)

# Mendapatkan nilai 'catching_up' dan 'latest_block_height'
catching_up=$(echo "$sync_info" | jq -r .catching_up)
latest_block_height=$(echo "$sync_info" | jq -r .latest_block_height)

# Memeriksa nilai 'catching_up' dan menampilkan pesan yang sesuai
if [ "$catching_up" == "true" ]; then
  echo "Node masih download. Total download $latest_block_height."
else
  echo "Node sudah tersingkron. $latest_block_height."
fi
EOF

# Memberikan hak akses eksekusi pada file cek-synch.sh
chmod +x cek-synch.sh

# enable and start service
sudo systemctl daemon-reload
sudo systemctl enable initiad
sudo systemctl restart initiad 

# Menampilkan log layanan Initia
echo "Setup selesai. Node Initia telah berhasil diinisialisasi!"
echo "Cek service bisa ketik sudo systemctl status initiad"
echo "Untuk cek status sync. Jalankan command ./cek-sync.sh"
sleep 5
