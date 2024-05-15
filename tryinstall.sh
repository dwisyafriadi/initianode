#!/bin/bash

# Menampilkan pesan informasi
echo '================================================================================================================'
echo 'Order VPS bisa garansi 30 hari dan Jasa Installasi Node WA : 081-214-827-906. Atau ke FB : Mochamad Dwi Syafriadi'
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
VERSION=1.22.3
wget -O go.tar.gz https://go.dev/dl/go$VERSION.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go.tar.gz && rm go.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile

# Menampilkan versi Go yang terinstall
go version
echo  # Baris kosong

# Mendeteksi OS
OS=$(lsb_release -si)

if [ "$OS" != "Ubuntu" ]; then
  echo "Unsupported OS. Please install GitHub CLI manually."
  exit 1
fi

# Mendeteksi arsitektur
ARCH=$(dpkg --print-architecture)

if [ "$ARCH" != "amd64" ]; then
  echo "Unsupported architecture. Please install GitHub CLI manually."
  exit 1
fi

# Memastikan `gh` (GitHub CLI) telah terinstal
if command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) is already installed."
else
  # Instal GitHub CLI menggunakan apt
  sudo apt install gh -y

  # Memeriksa kembali instalasi GitHub CLI
  if ! command -v gh &> /dev/null; then
    echo "Failed to install GitHub CLI. Please install GitHub CLI manually."
    exit 1
  else
    echo "GitHub CLI (gh) has been successfully installed."
  fi
fi

echo  # Baris kosong

# Konfigurasi Git untuk menggunakan personal access token (PAT)
read -p "Masukkan personal access token GitHub: " PAT
echo  # Baris kosong
git config --global url."https://x-access-token:$PAT@github.com/".insteadOf "https://github.com/"
echo "export GOPRIVATE=\"github.com/initia-labs/movevm,github.com/initia-labs/OPinit\"" >> $HOME/.bash_profile
echo  # Baris kosong

# Mengkloning repositori privat menggunakan SSH
git clone https://github.com/initia-labs/initia.git

# Berpindah ke direktori repositori yang baru saja dikloning
cd initia || { echo "Failed to change directory to 'initia'"; exit 1; }

echo  # Baris kosong

# Meminta input dari pengguna untuk tag versi yang diinginkan
read -p "Masukkan tag versi yang ingin diinstall (contoh: v0.2.14): " TAG
echo  # Baris kosong

# Memeriksa apakah input TAG tidak kosong
if [ -z "$TAG" ]; then
  echo "Error: TAG is not set. Please provide a valid tag version."
  exit 1
fi

echo  # Baris kosong

# Checkout ke tag yang diinginkan
git checkout "$TAG" || { echo "Failed to checkout tag $TAG"; exit 1; }

echo  # Baris kosong

# Membuat dan menginstal
echo "Menginstall dengan make..."
make install || { echo "Failed to install"; exit 1; }

echo  # Baris kosong

# Menunggu hingga make install selesai
while pgrep -x "make" > /dev/null; do
  echo "Waiting for make install to complete..."
  sleep 5
done

echo  # Baris kosong

# Pesan sukses
echo "Installation complete!"


# Menetapkan variabel lingkungan untuk unduhan file
export CHAINID="initiation-1" >> $HOME/.bash_profile
export VERSION="v0.2.12"      >> $HOME/.bash_profile
export OS="ubuntu"            >> $HOME/.bash_profile
export ARCH="x86_64"          >> $HOME/.bash_profile

# Mengunduh file yang diperlukan
wget https://initia.s3.ap-southeast-1.amazonaws.com/${CHAINID}/initia_${VERSION}_${OS}_${ARCH}.tar.gz

# Mengekstrak file yang diunduh dan menghapus file arsip
tar -xzf initia_${VERSION}_${OS}_${ARCH}.tar.gz && rm initia_${VERSION}_${OS}_${ARCH}.tar.gz

# Memindahkan file biner dan library ke lokasi yang sesuai
sudo mv initiad /usr/bin
sudo mv libmovmvm.${ARCH}.so /usr/lib
sudo mv libcompiler.${ARCH}.so /usr/lib

source $HOME/.bash_profile

# Memeriksa versi yang terinstal
initiad version

# Memastikan bahwa library terhubung dengan benar
ldd 'which initiad'

# Inisialisasi node Initia
read -p "Masukkan nama moniker untuk node Anda: " MONIKER
initiad init "$MONIKER"

echo  # Baris kosong

# Mengatur harga gas minimum
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"0.15uinit,0.01uusdc\"|" $HOME/.initia/config/app.toml

# Mengaktifkan dan mengkonfigurasi endpoint
sed -i -e "s|enable *=.*|enable = true|" $HOME/.initia/config/app.toml
sed -i -e "s|swagger *=.*|swagger = true|" $HOME/.initia/config/app.toml
sed -i -e "s|address *=.*|address = \"tcp://0.0.0.0:1317\"|" $HOME/.initia/config/app.toml
sed -i -e "s|enable *=.*|enable = true|" $HOME/.initia/config/app.toml
sed -i -e "s|address *=.*|address = \"0.0.0.0:9090\"|" $HOME/.initia/config/app.toml
sed -i -e "s|enable *=.*|enable = true|" $HOME/.initia/config/app.toml
sed -i -e "s|address *=.*|address = \"0.0.0.0:9091\"|" $HOME/.initia/config/app.toml
sed -i -e "s|laddr *=.*|laddr = \"tcp://0.0.0.0:26657\"|" $HOME/.initia/config/config.toml
sed -i -e "s|laddr *=.*|laddr = \"tcp://0.0.0.0:26656\"|" $HOME/.initia/config/config.toml

# Mengatur alamat eksternal untuk node
EXTERNAL_IP=$(curl -s httpbin.org/ip | jq -r .origin)
sed -i -e "s|external_address = \"\"|external_address = \"${EXTERNAL_IP}:26656\"|" $HOME/.initia/config/config.toml

# Mengatur oracle
sed -i -e "s|enabled *=.*|enabled = true|" $HOME/.initia/config/app.toml
sed -i -e "s|production *=.*|production = true|" $HOME/.initia/config/app.toml
sed -i -e "s|remote_address *=.*|remote_address = \"127.0.0.1:8080\"|" $HOME/.initia/config/app.toml
sed -i -e "s|client_timeout *=.*|client_timeout = \"500ms\"|" $HOME/.initia/config/app.toml



echo  # Baris kosong
echo -e '\n\e[42mSetting Systemd\e[0m\n' && sleep 1
echo  # Baris kosong

# Mendaftarkan Initia sebagai layanan
sudo tee /etc/systemd/system/initiad.service > /dev/null <<EOF
[Unit]
Description=initiad

[Service]
Type=simple
User=$(whoami)
ExecStart=/usr/bin/initiad start
Restart=on-abort
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=initiad
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

# Mengaktifkan layanan Initia
sudo systemctl enable initiad

# Memulai layanan Initia
sudo systemctl start initiad

# Memuat ulang konfigurasi layanan systemd
sudo systemctl daemon-reload
sudo systemctl restart initiad

# Menampilkan log layanan Initia
journalctl -t initiad -f
