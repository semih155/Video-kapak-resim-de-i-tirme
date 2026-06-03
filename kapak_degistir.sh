cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do
        [ "$satir" = "$aranan" ] && return 0
    done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1
    local toplam=$2
    if [ "$toplam" -le 0 ]; then toplam=1; fi
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 ))
    local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  [%s] %3d%%  (%d/%d)" "$bar" "$yuzde" "$mevcut" "$toplam"
}

ana_menu() {
    clear
    echo "========================================="
    echo "      KAPAK DEĞİŞTİRİCİ (HAFIZALI)      "
    echo "========================================="
    echo "  Resim : ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
    echo "-----------------------------------------"
    echo "  1 - Videoların Kapağını Güncelle"
    echo "  2 - Hafızayı Sil (Tüm videoları tekrar işle)"
    echo "  3 - Resim Ayarını Değiştir"
    echo "  4 - Çıkış"
    echo "========================================="
    read -p "Seçiminiz: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_RESIM" ]; then
                echo "  HATA: Önce resim ayarını yapın! (Seçenek 3)"
                sleep 2; ana_menu; return
            fi

            if [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo "  HATA: Resim bulunamadı: $VARSAYILAN_RESIM"
                sleep 2; ana_menu; return
            fi

            echo ""
            echo "  Son kullanılan klasör: ${VARSAYILAN_KLASOR:-'Yok'}"
            read -p "  Video Klasörü Tam Yolu: " girilen_klasor

            # Eğer boş bırakılırsa ve eski klasör varsa eskisini kullan
            if [ -z "$girilen_klasor" ]; then
                if [ -z "$VARSAYILAN_KLASOR" ]; then
                    echo "  İptal edildi."
                    sleep 1; ana_menu; return
                else
                    girilen_klasor="$VARSAYILAN_KLASOR"
                fi
            fi

            if [ ! -d "$girilen_klasor" ]; then
                echo "  HATA: Klasör bulunamadı: $girilen_klasor"
                sleep 2; ana_menu; return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"
            _kaydet_ayarlar

            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            # Boşluklu isimler için find komutunu güvenli hale getirdik
            find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST"

            toplam=$(wc -l < "$TEMP_LIST")

            if [ "$toplam" -eq 0 ]; then
                echo "  Bu klasörde hiç video bulunamadı!"
                rm -f "$TEMP_LIST"
                sleep 2; ana_menu; return
            fi

            zaten=0
            while IFS= read -r video; do
                [ -z "$video" ] && continue
                isim=$(basename "$video")
                _zaten_islendi_mi "$isim" && zaten=$((zaten + 1))
            done < "$TEMP_LIST"

            islencek=$((toplam - zaten))

            clear
            echo "========================================="
            echo "           İŞLEM BAŞLIYOR               "
            echo "========================================="
            echo "  Toplam video  : $toplam"
            echo "  Zaten yapılmış: $zaten"
            echo "  İşlenecek     : $islencek"
            echo "-----------------------------------------"

            if [ "$islencek" -eq 0 ]; then
                echo "  Tüm videolar zaten işlenmiş!"
                rm -f "$TEMP_LIST"
                read -p "  Enter'a bas..."
                ana_menu; return
            fi

            islem_sayisi=0
            hata_sayisi=0

            while IFS= read -r video; do
                [ -z "$video" ] && continue
                isim=$(basename "$video")
                klasor=$(dirname "$video")

                if _zaten_islendi_mi "$isim"; then
                    continue
                fi

                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$islencek"

                temp_dosya="$klasor/temp_${$}_${islem_sayisi}.mp4"

                # FFmpeg komutundaki tüm değişkenleri tırnak içine alarak sabitledik
                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
                    -map 0 -map 1 -c copy \
                    -disposition:v:1 attached_pic \
                    "$temp_dosya" -y -loglevel quiet 2>/dev/null

                if [ $? -eq 0 ] && [ -f "$temp_dosya" ]; then
                    mv "$temp_dosya" "$video"
                    echo "$isim" >> "$ISLENENLER_LISTESI"
                else
                    [ -f "$temp_dosya" ] && rm -f "$temp_dosya"
                    hata_sayisi=$((hata_sayisi + 1))
                fi

            done < "$TEMP_LIST"

            rm -f "$TEMP_LIST"

            echo ""
            echo "-----------------------------------------"
            echo "  ✓ Tamamlandı!"
            echo "  İşlenen : $islem_sayisi video"
            echo "  Hata    : $hata_sayisi video"
            echo "  Atlanan : $zaten video (zaten yapılmıştı)"
            echo "========================================="
            read -p "  Enter'a bas..."
            ana_menu
            ;;

        2)
            read -p "  Emin misiniz? (e/h): " onay
            if [ "$onay" = "e" ] || [ "$onay" = "E" ]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo "  Hafıza silindi."
            else
                echo "  İptal edildi."
            fi
            sleep 1; ana_menu
            ;;

        3)
            echo ""
            echo "  Mevcut resim: ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
            read -p "  Yeni Resim Tam Yolu (boş bırakırsan değişmez): " yeni_r
            if [ ! -z "$yeni_r" ]; then
                if [ -f "$yeni_r" ]; then
                    VARSAYILAN_RESIM="$yeni_r"
                    _kaydet_ayarlar
                    echo "  Resim güncellendi."
                else
                    echo "  HATA: Dosya bulunamadı."
                fi
            else
                echo "  Değişiklik yapılmadı."
            fi
            sleep 1; ana_menu
            ;;

        4)
            exit 0
            ;;

        *)
            echo "  Geçersiz seçim!"
            sleep 1; ana_menu
            ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
echo "Kod temizlendi ve güncellendi!"
