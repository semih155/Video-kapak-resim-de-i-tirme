cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

# Sabit prefix
PREFIX="〖ذال فیلم تقدیم میکندょ〗"

# Şekilli Renk Tanımlamaları
RED='\033[1;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
BLUE='\033[1;34m'; MAGENTA='\033[1;35m'; CYAN='\033[1;36m'
WHITE='\033[1;37m'; BOLD='\033[1;1m'; RESET='\033[0m'

_kaydet_ayarlar() {
    echo "VARSAYILAN_KLASOR=\"$VARSAYILAN_KLASOR\"" > "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_RESIM=\"$VARSAYILAN_RESIM\"" >> "$HOME/.kapak_ayarlari.conf"
    echo "VARSAYILAN_MP3_KLASOR=\"$VARSAYILAN_MP3_KLASOR\"" >> "$HOME/.kapak_ayarlari.conf"
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
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 ))
    local bos=$(( 20 - dolu ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  ${CYAN}[${GREEN}%s${CYAN}] ${YELLOW}%3d%% ${MAGENTA}(%d/%d)${RESET}" "$bar" "$yuzde" "$mevcut" "$toplam"
}

# ─────────────────────────────────────────
# DOSYA YENİDEN ADLANDIRMA MODÜLÜ
# ─────────────────────────────────────────
adlandirma_menu() {
    while true; do
        clear
        echo -e "${CYAN}┌────────────────────────────────────────┐${RESET}"
        echo -e "${CYAN}│        KLASÖR SEÇİMİ MENÜSÜ            │${RESET}"
        echo -e "${CYAN}└────────────────────────────────────────┘${RESET}"
        echo -e "  ${YELLOW}[1]${WHITE} VidMate İndirilenleri İşle${RESET}"
        echo -e "  ${YELLOW}[2]${WHITE} SnapTube İndirilenleri İşle${RESET}"
        echo -e "  ${YELLOW}[3]${WHITE} VidMate & SnapTube Birlikte${RESET}"
        echo -e "  ${YELLOW}[4]${WHITE} Telegram Videolarını İşle${RESET}"
        echo -e "  ${YELLOW}[5]${WHITE} Tüm Müzikler${RESET}"
        echo -e "  ${YELLOW}[6]${WHITE} Özel Dizin Belirt${RESET}"
        echo -e "  ${RED}[0]${WHITE} Ana Menüye Dön${RESET}"
        echo -e "${CYAN}──────────────────────────────────────────${RESET}"
        read -p "  Seçiminiz [0-6]: " choice

        case "$choice" in
            1) DIRS=("/storage/emulated/0/VidMate/download"); MODE_TYPE="video" ;;
            2) DIRS=("/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            3) DIRS=("/storage/emulated/0/VidMate/download" "/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            4) DIRS=("/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video"); MODE_TYPE="video" ;;
            5) MODE_TYPE="music" ;;
            6)
               echo -e ""
               read -p "  Özel dizin yolunu girin: " custom_dir
               DIRS=("$custom_dir")
               MODE_TYPE="video"
               ;;
            0) ana_menu; return ;;
            *) echo -e "  ${RED}✗ Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        echo -e "\n${MAGENTA}┌── İŞLEM MODU SEÇİMİ ───────────────────┐${RESET}"
        echo -e "  ${YELLOW}[1]${WHITE} Prefix Ekle (${GREEN}$PREFIX${WHITE})${RESET}"
        echo -e "  ${YELLOW}[2]${WHITE} Metin Kaldır${RESET}"
        echo -e "  ${RED}[0]${WHITE} İptal Et / Ana Menü${RESET}"
        echo -e "${MAGENTA}└────────────────────────────────────────┘${RESET}"
        read -p "  Seçiminiz [0-2]: " op_mode

        case "$op_mode" in
            1) MODE_OP="add" ;;
            2) MODE_OP="remove" ;;
            0) ana_menu; return ;;
            *) echo -e "  ${RED}✗ Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        if [[ "$MODE_OP" == "add" ]]; then
            echo -e "  ${GREEN}✓ Prefix Modu Aktif.${RESET}"
        else
            echo -e ""
            read -p "  Kaldırılacak metni girin: " text_to_remove
            [[ -z "$text_to_remove" ]] && { echo -e "  ${RED}✗ Hiç metin girilmedi!${RESET}"; sleep 1; continue; }
            echo -e "  ${GREEN}✓ Kaldırılacak Metin: '${YELLOW}$text_to_remove${GREEN}'${RESET}"
        fi

        processed=0; skipped=0; failed=0
        LOG_FILE="$HOME/process_log.txt"
        echo "Başlatma: $(date)" > "$LOG_FILE"

        process_file(){
            local f="$1"; local base="$(basename "$f")"
            case "$base" in *.nomedia|*.txt|*.json)
                echo -e "  ${BLUE}→ Atlandı (Özel Dosya):${RESET} $base"
                ((skipped++)); echo "SKIP-ÖZEL: $base" >>"$LOG_FILE"; return ;;
            esac
            if [[ "$MODE_OP" == "add" ]]; then
                if [[ "$base" == "$PREFIX"* ]]; then
                    echo -e "  ${BLUE}→ Atlandı (Zaten Prefixli):${RESET} $base"
                    ((skipped++)); echo "SKIP-PREF: $base" >>"$LOG_FILE"; return
                fi
                local new="$PREFIX$base"
                if mv -- "$f" "$(dirname "$f")/$new"; then
                    echo -e "  ${GREEN}✓ Eklendi:${RESET} $base → $new"
                    ((processed++)); echo "ADD: $base → $new" >>"$LOG_FILE"
                else
                    echo -e "  ${RED}✗ Hata:${RESET} $base"
                    ((failed++)); echo "ERR-ADD: $base" >>"$LOG_FILE"
                fi
            else
                if [[ "$base" == *"$text_to_remove"* ]]; then
                    local cleaned="${base//$text_to_remove/}"
                    local target="$(dirname "$f")/$cleaned"
                    if [[ -z "$cleaned" || "$target" == "$f" ]]; then
                        echo -e "  ${BLUE}→ Atlandı (Geçersiz Hedef):${RESET} $base"
                        ((skipped++)); echo "SKIP-REM: $base" >>"$LOG_FILE"; return
                    fi
                    if mv -- "$f" "$target"; then
                        echo -e "  ${GREEN}✓ Kaldırıldı:${RESET} $base → $cleaned"
                        ((processed++)); echo "REM: $base → $cleaned" >>"$LOG_FILE"
                    else
                        echo -e "  ${RED}✗ Hata:${RESET} $base"
                        ((failed++)); echo "ERR-REM: $base" >>"$LOG_FILE"
                    fi
                else
                    echo -e "  ${BLUE}→ Atlandı (Metin Yok):${RESET} $base"
                    ((skipped++)); echo "SKIP-REM: $base" >>"$LOG_FILE"
                fi
            fi
        }

        if [[ "$MODE_TYPE" == "video" ]]; then
            for d in "${DIRS[@]}"; do
                echo -e "\n${CYAN}─── Tarama Başlıyor: ${YELLOW}$d${CYAN} ───${RESET}"
                while IFS= read -r -d '' file; do
                    process_file "$file"
                done < <(find "$d" -maxdepth 1 -type f -print0)
            done
        else
            echo -e "\n${CYAN}─── Tüm Müzikler Taranıyor ───${RESET}"
            while IFS= read -r -d '' file; do
                process_file "$file"
            done < <(find /storage/emulated/0 \
                -path "/storage/emulated/0/Android/data" -prune -o \
                -path "/storage/emulated/0/Android/obb" -prune -o \
                -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \
                -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" \) -print0)
        fi

        echo -e "\n${MAGENTA}┌── İŞLEM ÖZETİ ─────────────────────────┐${RESET}"
        echo -e "  ${GREEN}✓ İşlenen : $processed${RESET}"
        echo -e "  ${BLUE}→ Atlanan : $skipped${RESET}"
        echo -e "  ${RED}✗ Hatalı  : $failed${RESET}"
        echo -e "${MAGENTA}└────────────────────────────────────────┘${RESET}"
        read -p $'\n  Ana menüye dönmek için Enter...' _
        ana_menu; return
    done
}

# ─────────────────────────────────────────
# VİDEOLARI MP3'E DÖNÜŞTÜRME MODÜLÜ (ALBÜM KAPAKLI + PREFIX)
# ─────────────────────────────────────────
mp3_donusturucu_menu() {
    clear
    echo -e "${YELLOW}┌────────────────────────────────────────┐${RESET}"
    echo -e "${YELLOW}│      VİDEO -> MP3 DÖNÜŞTÜRME MOTORU    │${RESET}"
    echo -e "${YELLOW}└────────────────────────────────────────┘${RESET}"
    echo -e "  ${WHITE}Hafızadaki Klasör :${MAGENTA} ${VARSAYILAN_MP3_KLASOR:-'Yok'}${RESET}"
    echo -e "  ${WHITE}Gömülecek Kapak   :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "${YELLOW}──────────────────────────────────────────${RESET}"
    echo -e "  ${CYAN}ℹ Eski yolu kullanmak için bir şey yazmadan ENTER'a bas.${RESET}"
    read -p "  Video Klasörü Tam Yolu: " girilen_mp3_klasor

    if [ -z "$girilen_mp3_klasor" ]; then
        if [ -z "$VARSAYILAN_MP3_KLASOR" ]; then
            echo -e "  ${RED}✗ HATA: Hafızada klasör yok, bir yol girmelisiniz!${RESET}"
            sleep 2; ana_menu; return
        fi
        girilen_mp3_klasor="$VARSAYILAN_MP3_KLASOR"
    fi

    if [ ! -d "$girilen_mp3_klasor" ]; then
        echo -e "  ${RED}✗ HATA: Klasör bulunamadı: $girilen_mp3_klasor${RESET}"
        sleep 2; ana_menu; return
    fi

    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}✗ HATA: Önce ana menüden resim ayarını yapmalısınız!${RESET}"
        sleep 2; ana_menu; return
    fi

    VARSAYILAN_MP3_KLASOR="$girilen_mp3_klasor"
    _kaydet_ayarlar

    TEMP_MP3_LIST="$HOME/.mp3_listesi_tmp.txt"
    find "$VARSAYILAN_MP3_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" -o -iname "*.3gp" \) > "$TEMP_MP3_LIST"

    toplam_mp3=$(wc -l < "$TEMP_MP3_LIST")

    if [ "$toplam_mp3" -eq 0 ]; then
        echo -e "  ${RED}✗ Bu klasörde dönüştürülecek hiç video bulunamadı!${RESET}"
        rm -f "$TEMP_MP3_LIST"
        sleep 2; ana_menu; return
    fi

    CIKTI_MP3_DIR="$VARSAYILAN_MP3_KLASOR/MP3_Muzikler"
    mkdir -p "$CIKTI_MP3_DIR"

    clear
    echo -e "${GREEN}┌────────────────────────────────────────┐${RESET}"
    echo -e "${GREEN}│         MP3 DÖNÜŞTÜRME BAŞLADI         │${RESET}"
    echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
    echo -e "  ${WHITE}Toplam Video Dosyası:${YELLOW} $toplam_mp3${RESET}"
    echo -e "  ${WHITE}Prefix Markası      :${CYAN} $PREFIX${RESET}"
    echo -e "  ${WHITE}Albüm Kapağı Durumu :${GREEN} Gömülüyor (Oto Teyp Uyumlu)${RESET}"
    echo -e "  ${WHITE}Çıktı Klasörü       :${MAGENTA} $CIKTI_MP3_DIR${RESET}"
    echo -e "${GREEN}──────────────────────────────────────────${RESET}"

    mp3_islem_sayisi=0
    mp3_hata_sayisi=0

    while IFS= read -r video; do
        isim=$(basename "$video")
        isim_base="${isim%.*}"
        
        if [[ "$isim_base" == "$PREFIX"* ]]; then
            temiz_isim="${isim_base#$PREFIX}"
        else
            temiz_isim="$isim_base"
        fi

        mp3_islem_sayisi=$((mp3_islem_sayisi + 1))
        _ilerleme_goster "$mp3_islem_sayisi" "$toplam_mp3"

        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" -vn \
            -map 0:a:0 -map 1:v:0 -c:a mp3 -b:a 192k -ar 44100 -ac 2 \
            -c:v mjpeg -disposition:v attached_pic \
            -id3v2_version 3 -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" \
            "$CIKTI_MP3_DIR/${PREFIX}${temiz_isim}.mp3" -y -loglevel quiet 2>/dev/null

        if [ $? -ne 0 ]; then
            mp3_hata_sayisi=$((mp3_hata_sayisi + 1))
        fi
    done < "$TEMP_MP3_LIST"

    rm -f "$TEMP_MP3_LIST"

    echo -e "\n\n${GREEN}┌── İŞLEM TAMAMLANDI! ──────────────────┐${RESET}"
    echo -e "  ${GREEN}✓ Başarılı (Kapaklı MP3) : $((mp3_islem_sayisi - mp3_hata_sayisi))${RESET}"
    echo -e "  ${RED}✗ Başarısız / Hatalı     : $mp3_hata_sayisi${RESET}"
    echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
    read -p "  Devam etmek için Enter'a bas..." _
    ana_menu
}

# ─────────────────────────────────────────
# ANA MENÜ (RENGARENK & SAMIULLAH DILSUZ)
# ─────────────────────────────────────────
ana_menu() {
    clear
    echo -e "${MAGENTA}┌────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${MAGENTA}│${YELLOW}    👑   SAMIULLAH DILSUZ PRODUCTION   👑   ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}├────────────────────────────────────────────────────────┤${RESET}"
    echo -e "${MAGENTA}│${CYAN}    🎬   KAPAK DEĞİŞTİRİCİ & MP3 DÖNÜŞTÜRÜCÜ (HAFIZALI)  ${MAGENTA}│${RESET}"
    echo -e "${MAGENTA}└────────────────────────────────────────────────────────┘${RESET}"
    echo -e "  ${WHITE}Mevcut Resim  :${GREEN} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
    echo -e "  ${WHITE}Sabit Prefix  :${BLUE} $PREFIX${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    echo -e "  ${YELLOW}[1]${WHITE} Videoların Kapağını Güncelle ${CYAN}(Hafızalı Klasör + Prefix)${RESET}"
    echo -e "  ${YELLOW}[2]${WHITE} Videoları MP3'e Dönüştür    ${GREEN}(Albüm Kapaklı + Teyp Uyumlu)${RESET}"
    echo -e "  ${YELLOW}[3]${WHITE} Hafızayı Temizle            ${RED}(Tüm Videoları Baştan İşler)${RESET}"
    echo -e "  ${YELLOW}[4]${WHITE} Kapak Resmini Değiştir      ${YELLOW}(Yeni Resim Seçimi)${RESET}"
    echo -e "  ${YELLOW}[5]${WHITE} Dosya Yeniden Adlandır      ${BLUE}(Prefix Ekleme / Silme Menüsü)${RESET}"
    echo -e "  ${RED}[6]${WHITE} Güvenli Çıkış${RESET}"
    echo -e "${MAGENTA}──────────────────────────────────────────────────────────${RESET}"
    read -p "  Seçiminiz [1-6]: " secim

    case $secim in
        1)
            if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
                echo -e "  ${RED}✗ HATA: Önce resim ayarını yapın! (Seçenek 4)${RESET}"
                sleep 2; ana_menu; return
            fi

            echo ""
            echo -e "  ${WHITE}Hafızadaki Klasör:${YELLOW} ${VARSAYILAN_KLASOR:-'Yok'}${RESET}"
            echo -e "  ${CYAN}ℹ Eski yolu kullanmak için bir şey yazmadan ENTER'a bas.${RESET}"
            read -p "  Video Klasörü Tam Yolu: " girilen_klasor

            if [ -z "$girilen_klasor" ]; then
                if [ -z "$VARSAYILAN_KLASOR" ]; then
                    echo -e "  ${RED}✗ HATA: Hafızada klasör yok, bir yol girmelisiniz!${RESET}"
                    sleep 2; ana_menu; return
                fi
                girilen_klasor="$VARSAYILAN_KLASOR"
            fi

            if [ ! -d "$girilen_klasor" ]; then
                echo -e "  ${RED}✗ HATA: Klasör bulunamadı: $girilen_klasor${RESET}"
                sleep 2; ana_menu; return
            fi

            VARSAYILAN_KLASOR="$girilen_klasor"
            _kaydet_ayarlar

            TEMP_LIST="$HOME/.video_listesi_tmp.txt"
            find "$VARSAYILAN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST"

            toplam=$(wc -l < "$TEMP_LIST")

            if [ "$toplam" -eq 0 ]; then
                echo -e "  ${RED}✗ Bu klasörde hiç video bulunamadı!${RESET}"
                rm -f "$TEMP_LIST"
                sleep 2; ana_menu; return
            fi

            zaten=0
            while IFS= read -r video; do
                isim=$(basename "$video")
                _zaten_islendi_mi "$isim" && zaten=$((zaten + 1))
            done < "$TEMP_LIST"

            islencek=$((toplam - zaten))

            clear
            echo -e "${CYAN}┌────────────────────────────────────────┐${RESET}"
            echo -e "${CYAN}│           KAPAK İŞLEMİ BAŞLADI         │${RESET}"
            echo -e "${CYAN}└────────────────────────────────────────┘${RESET}"
            echo -e "  ${WHITE}Toplam Video    :${YELLOW} $toplam${RESET}"
            echo -e "  ${WHITE}Zaten İşlenmiş  :${BLUE} $zaten${RESET}"
            echo -e "  ${WHITE}İşlenecek Olan  :${MAGENTA} $islencek${RESET}"
            echo -e "${CYAN}──────────────────────────────────────────${RESET}"

            if [ "$islencek" -eq 0 ]; then
                echo -e "  ${GREEN}✓ Tüm videolar zaten daha önceden işlenmiş!${RESET}"
                rm -f "$TEMP_LIST"
                read -p "  Enter'a bas..." _
                ana_menu; return
            fi

            islem_sayisi=0
            hata_sayisi=0

            while IFS= read -r video; do
                isim=$(basename "$video")
                klasor=$(dirname "$video")

                _zaten_islendi_mi "$isim" && continue

                islem_sayisi=$((islem_sayisi + 1))
                _ilerleme_goster "$islem_sayisi" "$islencek"

                temp_dosya="$klasor/temp_$$_$islem_sayisi.mp4"

                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
                    -map 0 -map 1 -c copy \
                    -disposition:v:1 attached_pic \
                    "$temp_dosya" -y -loglevel quiet 2>/dev/null

                if [ $? -eq 0 ]; then
                    uzanti="${isim##*.}"
                    isim_base="${isim%.*}"
                    if [[ "$isim" == "$PREFIX"* ]]; then
                        mv "$temp_dosya" "$video"
                        yeni_isim="$isim"
                    else
                        yeni_isim="${PREFIX}${isim}"
                        mv "$temp_dosya" "$klasor/$yeni_isim"
                        rm -f "$video"
                    fi
                    echo "$yeni_isim" >> "$ISLENENLER_LISTESI"
                else
                    rm -f "$temp_dosya"
                    hata_sayisi=$((hata_sayisi + 1))
                fi

            done < "$TEMP_LIST"

            rm -f "$TEMP_LIST"

            echo -e "\n\n${GREEN}┌── İŞLEM TAMAMLANDI! ──────────────────┐${RESET}"
            echo -e "  ${GREEN}✓ İşlenen Görüntü: $islem_sayisi video${RESET}"
            echo -e "  ${RED}✗ Hatalı Görüntü : $hata_sayisi video${RESET}"
            echo -e "  ${BLUE}→ Atlanan        : $zaten video${RESET}"
            echo -e "${GREEN}└────────────────────────────────────────┘${RESET}"
            read -p "  Devam etmek için Enter'a bas..." _
            ana_menu
            ;;

        2)
            mp3_donusturucu_menu
            ;;

        3)
            echo ""
            read -p "  Hafıza silinsin mi? Tüm videolar baştan işlenir! (e/h): " onay
            if [ "$onay" = "e" ] || [ "$onay" = "E" ]; then
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo -e "  ${GREEN}✓ Hafıza başarıyla temizlendi.${RESET}"
            else
                echo -e "  ${BLUE}→ İptal edildi.${RESET}"
            fi
            sleep 1; ana_menu
            ;;

        4)
            echo ""
            echo -e "  ${WHITE}Mevcut Resim:${YELLOW} ${VARSAYILAN_RESIM:-'Ayarlanmamış'}${RESET}"
            read -p "  Yeni Resim Tam Yolu (Boş bırakırsan değişmez): " yeni_r
            if [ ! -z "$yeni_r" ]; then
                if [ -f "$yeni_r" ]; then
                    VARSAYILAN_RESIM="$yeni_r"
                    _kaydet_ayarlar
                    echo -e "  ${GREEN}✓ Kapak resmi başarıyla güncellendi.${RESET}"
                else
                    echo -e "  ${RED}✗ HATA: Dosya bulunamadı!${RESET}"
                fi
            else
                echo -e "  ${BLUE}→ Değişiklik yapılmadı.${RESET}"
            fi
            sleep 1; ana_menu
            ;;

        5)
            adlandirma_menu
            ;;

        6)
            echo -e "  ${CYAN}👋 SAMIULLAH DILSUZ iyi günler diler! Çıkılıyor...${RESET}"
            exit 0
            ;;

        *)
            echo -e "  ${RED}✗ Geçersiz seçim!${RESET}"
            sleep 1; ana_menu
            ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
echo "Rengarenk Görsel Tasarım Tamamlandı, Script Güncellendi!"
