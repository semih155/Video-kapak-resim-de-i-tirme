
termux-setup-storage && pkg update -y && pkg install git ffmpeg -y && git clone https://github.com/KULLANICI_ADIN/REPO_ADIN.git && cd REPO_ADIN && chmod +x kapak_degistir.sh && echo "alias kapak='bash \$(pwd)/kapak_degistir.sh'" >> ~/.bashrc && source ~/.bashrc && echo -e "\n\n\033[1;32m[+] KURULUM TAMAMLANDI! Artık sadece 'kapak' yazmanız yeterli.\033[0m\n"
