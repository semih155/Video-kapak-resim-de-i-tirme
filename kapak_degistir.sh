rm -f ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'SCRIPT_SONU'
#!/data/data/com.termux/files/usr/bin/bash

MEVCUT_PID=$$
ESKI_SURECLER=$(pgrep -f "kapak_degistir.sh")
for pid in $ESKI_SURECLER; do
    if [ "$pid" != "$MEVCUT_PID" ]; then kill -9 "$pid" 2>/dev/null; fi
done

CONFIG="$HOME/.kapak_ayarlari.conf"
ISLENENLER_LISTESI="$HOME/.islenenler.txt"
HATA_LOG="$HOME/.kapak_hata.log"
touch "$ISLENENLER_LISTESI"

[ -f "$CONFIG" ] && source "$CONFIG"
[ -z "$ALT_KLASOR_DAHIL" ] && ALT_KLASOR_DAHIL="1"

PREFIX="〖ذال فیلم تقدیم میکندョ〗"

RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; RESET='\033[0m'

_kaydet_ayarlar() {
    {
        echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\""
        echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\""
        echo "ALT_KLASOR_DAHIL=\"$ALT_KLASOR_DAHIL\""
    } > "$CONFIG"
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do [ "$satir" = "$aranan" ] && return 0; done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1; local toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 )); local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  ${CYAN}[${GREEN}%s${CYAN}] ${YELLOW}%3d%% ${MAGENTA}(%d/%d)${RESET}" "$bar" "$yuzde" "$mevcut" "$toplam"
}

_durum_metni() {
    [ "$ALT_KLASOR_DAHIL" = "1" ] && echo "AÇIK" || echo "KAPALI"
}

ana_menu() {
    clear
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo -e "${RED}✗ ffmpeg bulunamadı! 'pkg install ffmpeg' ile kurun.${RESET}"
        sleep 3
    fi
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   VİDEO KAPAK GÜNCELLEME MOTORU                   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Resim   :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}Aktif Klasör  :${GREEN} ${VARSAYILAN_KLASOR:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}Alt Klasörler :${YELLOW} $(_durum_metni)${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Videoların Kapağını Güncelle${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Hafıza Geçmişini Temizle    ${RED}(Baştan İşleme Alır)${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Ayarlar                     ${YELLOW}(Resim / Alt Klasör)${RESET}"
    echo -e "  ${BLUE}[4]${WHITE} Son Hata Loglarını Göster${RESET}"
    echo -e "  ${RED}[5]${WHITE} Güvenli Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-5]: " secim

    case $secim in
        1) _videolari_isle ;;
        2)
            read -p "  Hafıza temizlensin mi? (e/h): " onay
            if [[ "$onay" == "e" || "$onay" == "E" ]]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo -e "  ${GREEN}✓ Hafıza sıfırlandı.${RESET}"
            fi
            sleep 1; ana_menu ;;
        3) _ayarlar_menu ;;
        4)
            clear
            if [ -s "$HATA_LOG" ]; then
                echo -e "${YELLOW}── SON HATA LOGU ($HATA_LOG) ──${RESET}"
                tail -n 60 "$HATA_LOG"
            else
                echo -e "  ${GREEN}✓ Kayıtlı hata yok.${RESET}"
            fi
            echo ""
            read -p "  Enter'a bas..." _
            ana_menu ;;
        5) exit 0 ;;
        *) ana_menu ;;
    esac
}

_ayarlar_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${CYAN}                      ⚙  AYARLAR                          ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Aktif Resim   :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}Aktif Klasör  :${GREEN} ${VARSAYILAN_KLASOR:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${CYAN}Alt Klasörler :${YELLOW} $(_durum_metni)${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Kapak Resmini Değiştir${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Video Klasörünü Değiştir${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Alt Klasörleri Dahil Et: ${CYAN}Aç/Kapat${RESET} ${MAGENTA}(şu an: $(_durum_metni))${RESET}"
    echo -e "  ${YELLOW}[4]${WHITE} Ana Menüye Dön${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-4]: " secim

    case $secim in
        1)
            echo ""
            read -p "  Yeni Resim Tam Yolu: " yeni_r
            if [ -f "$yeni_r" ]; then
                VARSAYILAN_RESIM="$yeni_r"; _kaydet_ayarlar
                echo -e "  ${GREEN}✓ Kapak güncellendi.${RESET}"
            else
                echo -e "  ${RED}✗ Dosya bulunamadı!${RESET}"
            fi
            sleep 1; _ayarlar_menu ;;
        2)
            echo ""
            read -p "  Yeni Klasör Tam Yolu: " yeni_k
            if [ -d "$yeni_k" ]; then
                VARSAYILAN_KLASOR="$yeni_k"; _kaydet_ayarlar
                echo -e "  ${GREEN}✓ Klasör güncellendi.${RESET}"
            else
                echo -e "  ${RED}✗ Klasör bulunamadı!${RESET}"
            fi
            sleep 1; _ayarlar_menu ;;
        3)
            if [ "$ALT_KLASOR_DAHIL" = "1" ]; then
                ALT_KLASOR_DAHIL="0"
            else
                ALT_KLASOR_DAHIL="1"
            fi
            _kaydet_ayarlar
            echo -e "  ${GREEN}✓ Alt klasör ayarı: $(_durum_metni)${RESET}"
            sleep 1; _ayarlar_menu ;;
        4) ana_menu ;;
        *) _ayarlar_menu ;;
    esac
}

_videolari_isle() {
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ HATA: Önce Ayarlar'dan kapak resmi seçin!${RESET}"; sleep 2; ana_menu; return
    fi
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo -e "  ${RED}✗ HATA: ffmpeg kurulu değil veya bozuk!${RESET}"; sleep 2; ana_menu; return
    fi

    echo ""
    read -p "  [ENTER] veya Video Klasör Yolu: " girilen_klasor
    [ -z "$girilen_klasor" ] && girilen_klasor="$VARSAYILAN_KLASOR"
    if [ -z "$girilen_klasor" ] || [ ! -d "$girilen_klasor" ]; then
        echo -e "  ${RED}✗ HATA: Klasör bulunamadı!${RESET}"; sleep 2; ana_menu; return
    fi

    VARSAYILAN_KLASOR="$girilen_klasor"; _kaydet_ayarlar
    TEMP_LIST="$HOME/.video_listesi_tmp.txt"
    > "$HATA_LOG"

    if [ "$ALT_KLASOR_DAHIL" = "1" ]; then
        find "$VARSAYILAN_KLASOR" \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
    else
        find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST" 2>/dev/null
    fi
    toplam=$(wc -l < "$TEMP_LIST")

    if [ "$toplam" -eq 0 ]; then
        echo -e "  ${RED}✗ Klasörde video yok!${RESET}"; rm -f "$TEMP_LIST"; sleep 2; ana_menu; return
    fi

    zaten=0
    while IFS= read -r video; do
        _zaten_islendi_mi "$(basename "$video")" && zaten=$((zaten + 1))
    done < "$TEMP_LIST"
    islencek=$((toplam - zaten))

    clear
    echo -e "${CYAN}┌────────────────────────────────────────┐${RESET}"
    echo -e "${CYAN}│           KAPAK İŞLEMİ BAŞLADI         │${RESET}"
    echo -e "${CYAN}└────────────────────────────────────────┘${RESET}"
    echo -e "  ${CYAN}Toplam :${YELLOW} $toplam${RESET}  |  ${CYAN}Kalan :${MAGENTA} $islencek${RESET}  |  ${CYAN}Atlanan :${BLUE} $zaten${RESET}"
    echo -e "${CYAN}──────────────────────────────────────────${RESET}"

    if [ "$islencek" -eq 0 ]; then
        echo -e "  ${GREEN}✓ Tüm videolar zaten yapılmış!${RESET}"; rm -f "$TEMP_LIST"; read -p "  Enter..." _; ana_menu; return
    fi

    islem_sayisi=0; basarili_sayisi=0; hata_sayisi=0
    while IFS= read -r video; do
        isim=$(basename "$video"); klasor=$(dirname "$video")
        _zaten_islendi_mi "$isim" && continue

        islem_sayisi=$((islem_sayisi + 1))
        _ilerleme_goster "$islem_sayisi" "$islencek"

        uzanti="${isim##*.}"
        temp_dosya="$klasor/temp_${MEVCUT_PID}_${islem_sayisi}.${uzanti}"

        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
            -map 0:v:0 -map 0:a? -map 1:v:0 \
            -c copy -c:v:1 mjpeg -disposition:v:1 attached_pic \
            "$temp_dosya" -y -loglevel error 2>>"$HATA_LOG"

        if [ $? -eq 0 ] && [ -s "$temp_dosya" ]; then
            if [[ "$isim" == "$PREFIX"* ]]; then
                mv "$temp_dosya" "$video" 2>/dev/null; yeni_isim="$isim"
            else
                yeni_isim="${PREFIX}${isim}"
                mv "$temp_dosya" "$klasor/$yeni_isim" 2>/dev/null; rm -f "$video"
            fi
            echo "$yeni_isim" >> "$ISLENENLER_LISTESI"
            basarili_sayisi=$((basarili_sayisi + 1))
        else
            echo "----- $isim -----" >> "$HATA_LOG"
            rm -f "$temp_dosya"; hata_sayisi=$((hata_sayisi + 1))
        fi
    done < "$TEMP_LIST"
    rm -f "$TEMP_LIST"

    echo -e "\n\n${GREEN}┌── İŞLEM ÖZETİ ─────────────────────────┐${RESET}"
    echo -e "  ${GREEN}✓ Başarılı   : $basarili_sayisi Video${RESET}"
    echo -e "  ${RED}✗ Hatalı     : $hata_sayisi Video${RESET}"
    if [ "$hata_sayisi" -gt 0 ]; then
        echo -e "  ${YELLOW}ℹ Detaylar: [4] Son Hata Loglarını Göster${RESET}"
    fi
    echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
    read -p "  Enter'a bas..." _
    ana_menu
}

ana_menu
SCRIPT_SONU
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
bash -n ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh && echo "✓ SÖZDİZİMİ TEMİZ" || echo "✗ HATA VAR"
