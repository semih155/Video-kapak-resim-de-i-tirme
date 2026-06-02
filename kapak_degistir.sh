#!/data/data/com.termux/files/usr/bin/bash

# Ayarları yükle
[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

ana_menu() {
    clear
    echo "========================================="
    echo "      KAPAK DEĞİŞTİRİCİ (HAFIZALI)      "
    echo "========================================="
    echo "  Klasör : ${VARSAYILAN_KLASOR:-'Ayarlanmamış'}"
    echo "  Resim  : ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
    echo "-----------------------------------------"
    echo "  1 - Yeni Videoların Kapağını Güncelle"
    echo "  2 - Hafızayı Sil (Tüm videoları tekrar işle)"
    echo "  3 - Klasör Ayarını Değiştir"
    echo "  4 - Resim Ayarını Değiştir"
    echo "  5 - Çıkış"
    echo "========================================="
    read -p "Seçiminiz: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_KLASOR" ] || [ -z "$VARSAYILAN_RESIM" ]; then
                echo "HATA: Önce klasör ve resim ayarlarını yapın! (Seçenek 3 ve 4)"
                sleep 2
                ana_menu
                return
            fi

            if [ ! -d "$VARSAYILAN_KLASOR" ]; then
                echo "HATA: Klasör bulunamadı: $VARSAYILAN_KLASOR"
                sleep 2
                ana_menu
                return
            fi

            if [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo "HATA: Resim bulunamadı: $VARSAYILAN_RESIM"
                sleep 2
                ana_menu
                return
            fi

            cd "$VARSAYILAN_KLASOR"
            islem_sayisi=0
            atlanan_sayisi=0

            for video in *.mp4 *.mkv; do
                [ -e "$video" ] || continue

                if grep -Fxq "$video" "$ISLENENLER_LISTESI"; then
                    echo "  [ATLANDI] $video"
                    atlanan_sayisi=$((atlanan_sayisi + 1))
                else
                    echo "  [İŞLENİYOR] $video ..."
                    ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
                        -map 0 -map 1 -c copy \
                        -disposition:v:1 attached_pic \
                        "temp_$(basename "$video")" -y -loglevel quiet

                    if [ $? -eq 0 ]; then
                        mv "temp_$(basename "$video")" "$video"
                        echo "$video" >> "$ISLENENLER_LISTESI"
                        echo "  [TAMAM] $video"
                        islem_sayisi=$((islem_sayisi + 1))
                    else
                        rm -f "temp_$(basename "$video")"
                        echo "  [HATA] $video işlenemedi!"
                    fi
                fi
            done

            echo "-----------------------------------------"
            echo "  Tamamlandı: $islem_sayisi video işlendi, $atlanan_sayisi atlandı."
            read -p "  Enter'a bas..."
            ana_menu
            ;;

        2)
            read -p "Hafızayı silmek istediğinize emin misiniz? (e/h): " onay
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
            echo "  Mevcut klasör: ${VARSAYILAN_KLASOR:-'Ayarlanmamış'}"
            read -p "  Yeni Klasör Yolu (boş bırakırsan değişmez): " yeni_k
            if [ ! -z "$yeni_k" ]; then
                if [ -d "$yeni_k" ]; then
                    VARSAYILAN_KLASOR="$yeni_k"
                    _kaydet_ayarlar
                    echo "  Klasör güncellendi: $VARSAYILAN_KLASOR"
                else
                    echo "  HATA: Klasör bulunamadı, değişiklik yapılmadı."
                fi
            else
                echo "  Değişiklik yapılmadı."
            fi
            sleep 1
            ana_menu
            ;;

        4)
            echo ""
            echo "  Mevcut resim: ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
            read -p "  Yeni Resim Yolu (boş bırakırsan değişmez): " yeni_r
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

        5)
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

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
}

ana_menu
