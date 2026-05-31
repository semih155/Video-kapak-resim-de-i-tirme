#!/data/data/com.termux/files/usr/bin/bash

# Ayarları yükle
[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

ana_menu() {
    clear
    echo "--- KAPAK DEĞİŞTİRİCİ (HAFIZALI) ---"
    echo "1 - Yeni Videoların Kapağını Güncelle"
    echo "2 - Hafızayı Sil (Tüm videoları tekrar işle)"
    echo "3 - Ayarları Düzenle"
    echo "4 - Çıkış"
    read -p "Seçiminiz: " secim

    case $secim in
        1)
            cd "$VARSAYILAN_KLASOR"
            for video in *.{mp4,mkv}; do
                [ -e "$video" ] || continue
                
                # Hafıza kontrolü: Dosya listede var mı?
                if grep -Fxq "$video" "$ISLENENLER_LISTESI"; then
                    echo "Atlandı (Zaten yapılmış): $video"
                else
                    echo "İşleniyor: $video"
                    ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -map 0 -map 1 -c copy -disposition:v:1 attached_pic "temp_$(basename "$video")" -y -loglevel quiet
                    if [ $? -eq 0 ]; then
                        mv "temp_$(basename "$video")" "$video"
                        echo "$video" >> "$ISLENENLER_LISTESI" # Listeye ekle
                    fi
                fi
            done
            read -p "İşlem bitti. Enter'a bas..."
            ana_menu
            ;;
        2)
            rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
            echo "Hafıza silindi."
            sleep 1
            ana_menu
            ;;
        3) 
            read -p "Yeni Klasör Yolu: " yeni_k
            read -p "Yeni Resim Yolu: " yeni_r
            [ ! -z "$yeni_k" ] && VARSAYILAN_KLASOR="$yeni_k"
            [ ! -z "$yeni_r" ] && VARSAYILAN_RESIM="$yeni_r"
            echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
            echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
            ana_menu
            ;;
        4) exit 0 ;;
    esac
}

ana_menu
