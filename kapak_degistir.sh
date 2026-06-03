#!/data/data/com.termux/files/usr/bin/bash

# Ayarları yükle
[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
}

_ilerleme_goster() {
    local mevcut=$1
    local toplam=$2
    local video_adi=$3
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 ))      # 20 karakterlik bar (her 5% = 1 blok)
    local bos=$(( 20 - dolu ))

    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done

    # Aynı satırı güncelle (üzerine yaz)
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
                sleep 2
                ana_menu
                return
            fi

            if [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo "  HATA: Resim bulunamadı: $VARSAYILAN_RESIM"
                sleep 2
                ana_menu
                return
            fi

            echo ""
            echo "  Son kullanılan klasör: ${VARSAYILAN_KLASOR:-'Yok'}"
            read -p "  Video Klasörü Tam Yolu: " girilen_klasor

            if [ -z "$girilen_klasor" ]; then
                echo "  İptal edildi."
                sleep 1
                ana_menu
                return
            fi

            if [ ! -d "$girilen_klasor" ]; then
                echo "  HATA: Klasör bulunamadı: $girilen_klasor"
                sleep 2
                ana_menu
                return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"
            _kaydet_ayarlar
            cd "$VARSAYILAN_KLASOR"

            # Önce toplam video sayısını say
            toplam=0
            for video in *.mp4 *.mkv; do
                [ -e "$video" ] || continue
                toplam=$((toplam + 1))
            done

            if [ $toplam -eq 0 ]; then
                echo "  Bu klasörde hiç video bulunamadı!"
                sleep 2
                ana_menu
                return
            fi

            # Kaçı zaten işlenmiş?
            zaten=0
            for video in *.mp4 *.mkv; do
                [ -e "$video" ] || continue
                grep -Fxq "$video" "$ISLENENLER_LISTESI" && zaten=$((zaten + 1))
            done
            islencek=$((toplam - zaten))

            clear
            echo "========================================="
            echo "           İŞLEM BAŞLIYOR               "
            echo "========================================="
            echo "  Toplam video  : $toplam"
            echo "  Zaten yapılmış: $zaten"
            echo "  İşlenecek     : $islencek"
            echo "-----------------------------------------"

            if [ $islencek -eq 0 ]; then
                echo "  Tüm videolar zaten işlenmiş!"
                read -p "  Enter'a bas..."
                ana_menu
                return
            fi

            siradaki=0
            islem_sayisi=0
            hata_sayisi=0

            for video in *.mp4 *.mkv; do
                [ -e "$video" ] || continue
                siradaki=$((siradaki + 1))

                if grep -Fxq "$video" "$ISLENENLER_LISTESI"; then
                    continue
                fi

                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$islencek" "$video"

                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
                    -map 0 -map 1 -c copy \
                    -disposition:v:1 attached_pic \
                    "temp_$(basename "$video")" -y -loglevel quiet 2>/dev/null

                if [ $? -eq 0 ]; then
                    mv "temp_$(basename "$video")" "$video"
                    echo "$video" >> "$ISLENENLER_LISTESI"
                else
                    rm -f "temp_$(basename "$video")"
                    hata_sayisi=$((hata_sayisi + 1))
                fi
            done

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
            read -p "  Hafızayı silmek istediğinize emin misiniz? (e/h): " onay
            if [ "$onay" = "e" ] || [ "$onay" = "E" ]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo "  Hafıza silindi. Tüm videolar tekrar işlenecek."
            else
                echo "  İptal edildi."
            fi
            sleep 1
            ana_menu
            ;;

        3)
            echo ""
            echo "  Mevcut resim: ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
            read -p "  Yeni Resim Tam Yolu (boş bırakırsan değişmez): " yeni_r
            if [ ! -z "$yeni_r" ]; then
                if [ -f "$yeni_r" ]; then
                    VARSAYILAN_RESIM="$yeni_r"
                    _kaydet_ayarlar
                    echo "  Resim güncellendi: $VARSAYILAN_RESIM"
                else
                    echo "  HATA: Resim dosyası bulunamadı, değişiklik yapılmadı."
                fi
            else
                echo "  Değişiklik yapılmadı."
            fi
            sleep 1
            ana_menu
            ;;

        4)
            echo "  Çıkılıyor..."
            exit 0
            ;;

        *)
            echo "  Geçersiz seçim!"
            sleep 1
            ana_menu
            ;;
    esac
}

ana_menu
