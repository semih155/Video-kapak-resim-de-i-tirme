cat > ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

[ -f "$HOME/.kapak_ayarlari.conf" ] && source "$HOME/.kapak_ayarlari.conf"

ISLENENLER_LISTESI="$HOME/.islenenler.txt"
touch "$ISLENENLER_LISTESI"

PREFIX="〖ذال فیلم تقدیم میکندょ〗"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; RESET='\033[0m'

# ─────────────────────────────────────────
# AYARLARI KAYDET
# ─────────────────────────────────────────
_kaydet_ayarlar() {
    cat > "$HOME/.kapak_ayarlari.conf" << CONF
VARSAYILAN_RESIM="$VARSAYILAN_RESIM"
MP3_KALITE="$MP3_KALITE"
SON_KAPAK_KLASOR="$SON_KAPAK_KLASOR"
SON_MP3_KAYNAK="$SON_MP3_KAYNAK"
SON_MP3_KALITE="$SON_MP3_KALITE"
SON_MUZIK_KLASOR="$SON_MUZIK_KLASOR"
CONF
}

_zaten_islendi_mi() {
    local aranan="$1"
    while IFS= read -r satir; do
        [ "$satir" = "$aranan" ] && return 0
    done < "$ISLENENLER_LISTESI"
    return 1
}

_ilerleme_goster() {
    local mevcut=$1 toplam=$2
    local yuzde=$(( mevcut * 100 / toplam ))
    local dolu=$(( yuzde / 5 )) bos=$(( 20 - yuzde / 5 ))
    local bar=""
    for ((i=0; i<dolu; i++)); do bar+="█"; done
    for ((i=0; i<bos; i++));  do bar+="░"; done
    printf "\r  [%s] %3d%%  (%d/%d)" "$bar" "$yuzde" "$mevcut" "$toplam"
}

# ─────────────────────────────────────────
# KAYNAK KLASÖR SEÇİM YARDIMCISI
# Kullanım: _kaynak_sec "Başlık" "SON_DEG_ADI"
# Seçilen yolu SECILEN_KLASOR değişkenine yazar
# ─────────────────────────────────────────
_kaynak_sec() {
    local baslik="$1"
    local son_deger="$2"   # örn: "$SON_KAPAK_KLASOR"

    echo -e "\n${YELLOW}[ $baslik ]${RESET}"
    echo -e "  1) VidMate indirmeleri"
    echo -e "  2) SnapTube indirmeleri"
    echo -e "  3) VidMate & SnapTube birlikte"
    echo -e "  4) Telegram videoları"
    echo -e "  5) Özel dizin belirt"
    if [ -n "$son_deger" ]; then
        echo -e "  ${GREEN}[Enter] Son kullanılan: $son_deger${RESET}"
    fi
    echo -e "  0) Ana Menüye Dön"
    read -p "Seçiminiz [0-5]: " _src

    case "$_src" in
        "")
            if [ -n "$son_deger" ]; then
                SECILEN_KLASOR="$son_deger"
            else
                echo -e "${RED}Kayıtlı klasör yok!${RESET}"; SECILEN_KLASOR=""; return 1
            fi
            ;;
        1) SECILEN_KLASOR="/storage/emulated/0/VidMate/download" ;;
        2) SECILEN_KLASOR="/storage/emulated/0/snaptube/download/SnapTube Video" ;;
        3) SECILEN_KLASOR="VidMate+SnapTube" ;;
        4) SECILEN_KLASOR="/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video" ;;
        5)
           read -p "Dizin yolunu girin: " _custom
           if [ -z "$_custom" ] || [ ! -d "$_custom" ]; then
               echo -e "${RED}Geçersiz dizin!${RESET}"; SECILEN_KLASOR=""; return 1
           fi
           SECILEN_KLASOR="$_custom"
           ;;
        0) ana_menu; return 2 ;;
        *) echo -e "${RED}Geçersiz seçim!${RESET}"; SECILEN_KLASOR=""; return 1 ;;
    esac
    return 0
}

# ─────────────────────────────────────────
# 1) KAPAK DEĞİŞTİRME
# Aynı klasörde değişir — prefix ekler, kopya kalmaz
# ─────────────────────────────────────────
kapak_degistir_isle() {
    if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
        echo -e "  ${RED}HATA: Önce resim ayarını yapın! (Seçenek 3)${RESET}"
        sleep 2; ana_menu; return
    fi

    clear
    echo -e "${CYAN}=========================================${RESET}"
    echo -e "${CYAN}      Kapak Değiştirme - Klasör Seç${RESET}"
    echo -e "${CYAN}=========================================${RESET}"

    _kaynak_sec "Video Klasörü Seçin" "$SON_KAPAK_KLASOR"
    local ret=$?
    [ $ret -eq 2 ] && return
    [ $ret -eq 1 ] && { sleep 1; kapak_degistir_isle; return; }
    [ -z "$SECILEN_KLASOR" ] && { sleep 1; kapak_degistir_isle; return; }

    # VidMate+SnapTube burada tek klasör olmaz, video kapak için tek yol lazım
    if [[ "$SECILEN_KLASOR" == "VidMate+SnapTube" ]]; then
        echo -e "${RED}Bu mod için tek bir klasör seçin.${RESET}"; sleep 2; kapak_degistir_isle; return
    fi

    if [ ! -d "$SECILEN_KLASOR" ]; then
        echo -e "  ${RED}HATA: Klasör bulunamadı: $SECILEN_KLASOR${RESET}"
        sleep 2; kapak_degistir_isle; return
    fi

    SON_KAPAK_KLASOR="$SECILEN_KLASOR"
    _kaydet_ayarlar

    TEMP_LIST="$HOME/.video_listesi_tmp.txt"
    find "$SECILEN_KLASOR" -maxdepth 1 \( -iname "*.mp4" -o -iname "*.mkv" \) > "$TEMP_LIST"
    toplam=$(wc -l < "$TEMP_LIST")

    if [ "$toplam" -eq 0 ]; then
        echo -e "  ${RED}Bu klasörde hiç video bulunamadı!${RESET}"
        rm -f "$TEMP_LIST"; sleep 2; ana_menu; return
    fi

    zaten=0
    while IFS= read -r video; do
        _zaten_islendi_mi "$(basename "$video")" && zaten=$((zaten + 1))
    done < "$TEMP_LIST"
    islencek=$((toplam - zaten))

    clear
    echo "========================================="
    echo "           İŞLEM BAŞLIYOR               "
    echo "========================================="
    echo "  Klasör       : $SECILEN_KLASOR"
    echo "  Toplam video : $toplam"
    echo "  Zaten yapıldı: $zaten"
    echo "  İşlenecek    : $islencek"
    echo "-----------------------------------------"

    if [ "$islencek" -eq 0 ]; then
        echo "  Tüm videolar zaten işlenmiş!"
        rm -f "$TEMP_LIST"; read -p "  Enter'a bas..."; ana_menu; return
    fi

    islem_sayisi=0; hata_sayisi=0

    while IFS= read -r video; do
        isim=$(basename "$video")
        klasor=$(dirname "$video")
        _zaten_islendi_mi "$isim" && continue

        islem_sayisi=$((islem_sayisi + 1))
        _ilerleme_goster "$islem_sayisi" "$islencek"

        temp_dosya="$klasor/.tmp_kapak_$$_${islem_sayisi}.mp4"

        ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
            -map 0 -map 1 -c copy \
            -disposition:v:1 attached_pic \
            "$temp_dosya" -y -loglevel quiet 2>/dev/null

        if [ $? -eq 0 ]; then
            if [[ "$isim" == "$PREFIX"* ]]; then
                # Zaten prefix var — sadece yerinde değiştir
                mv "$temp_dosya" "$video"
                yeni_isim="$isim"
            else
                # Prefix ekle, eski dosyayı sil
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
    echo ""
    echo "-----------------------------------------"
    echo "  ✓ Tamamlandı!"
    echo "  İşlenen : $islem_sayisi video"
    echo "  Hata    : $hata_sayisi video"
    echo "  Atlanan : $zaten video (zaten yapılmıştı)"
    echo "========================================="
    read -p "  Enter'a bas..."
    ana_menu
}
# ─────────────────────────────────────────
# 5) MP3 DÖNÜŞTÜRME
# Video neredeyse MP3 oraya kaydedilir — kopya kalmaz
# ─────────────────────────────────────────
mp3_donustur_menu() {
    while true; do
        clear
        echo -e "\n${CYAN}========================================${RESET}"
        echo -e "${CYAN}        MP3 Dönüştürme Menüsü${RESET}"
        echo -e "${CYAN}========================================${RESET}"

        if [ -n "$SON_MP3_KAYNAK" ]; then
            echo -e "  ${YELLOW}━━━ Son Kullanılan ━━━${RESET}"
            echo -e "  Kaynak : $SON_MP3_KAYNAK"
            echo -e "  Kalite : ${SON_MP3_KALITE:-'?'}"
            echo -e "  Çıktı  : ${CYAN}Video ile aynı klasör${RESET}"
            echo ""
            echo -e "  ${GREEN}[Enter]  Aynı ayarlarla devam${RESET}"
            echo -e "  ${CYAN}[d]      Farklı ayar seç${RESET}"
            echo -e "  ${RED}[0]      Ana Menüye Dön${RESET}"
            read -p "  Seçiminiz: " hizli_sec
            case "$hizli_sec" in
                "") : ;;   # aynen devam
                0) ana_menu; return ;;
                d|D)
                    _kaynak_sec "Kaynak Klasör Seçin" "$SON_MP3_KAYNAK"
                    local ret=$?
                    [ $ret -eq 2 ] && return
                    [ $ret -ne 0 ] && { sleep 1; continue; }
                    SON_MP3_KAYNAK="$SECILEN_KLASOR"

                    echo -e "\n${YELLOW}[ MP3 Kalitesi ]${RESET}"
                    echo -e "  1) 128k  2) 192k  3) 320k"
                    read -p "Seçiminiz [1-3]: " q
                    case "$q" in
                        1) MP3_KALITE="128k" ;; 2) MP3_KALITE="192k" ;; 3) MP3_KALITE="320k" ;;
                        *) echo -e "${RED}Geçersiz!${RESET}"; sleep 1; continue ;;
                    esac
                    SON_MP3_KALITE="$MP3_KALITE"
                    _kaydet_ayarlar
                    ;;
                *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
            esac
        else
            # İlk kez
            _kaynak_sec "Kaynak Klasör Seçin" ""
            local ret=$?
            [ $ret -eq 2 ] && return
            [ $ret -ne 0 ] && { sleep 1; continue; }
            SON_MP3_KAYNAK="$SECILEN_KLASOR"

            echo -e "\n${YELLOW}[ MP3 Kalitesi ]${RESET}"
            echo -e "  1) 128k  2) 192k  3) 320k"
            read -p "Seçiminiz [1-3]: " q
            case "$q" in
                1) MP3_KALITE="128k" ;; 2) MP3_KALITE="192k" ;; 3) MP3_KALITE="320k" ;;
                *) echo -e "${RED}Geçersiz!${RESET}"; sleep 1; continue ;;
            esac
            SON_MP3_KALITE="$MP3_KALITE"
            _kaydet_ayarlar
        fi

        # Klasörleri belirle
        if [[ "$SON_MP3_KAYNAK" == "VidMate+SnapTube" ]]; then
            SRC_DIRS=("/storage/emulated/0/VidMate/download" "/storage/emulated/0/snaptube/download/SnapTube Video")
        else
            SRC_DIRS=("$SON_MP3_KAYNAK")
        fi

        VIDEO_LISTESI="$HOME/.mp3_donustur_tmp.txt"
        > "$VIDEO_LISTESI"
        for d in "${SRC_DIRS[@]}"; do
            [[ -d "$d" ]] && find "$d" -maxdepth 1 -type f \
                \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.webm" \
                   -o -iname "*.avi" -o -iname "*.mov" \) >> "$VIDEO_LISTESI"
        done

        toplam=$(wc -l < "$VIDEO_LISTESI")
        if [[ "$toplam" -eq 0 ]]; then
            echo -e "${RED}  Bu klasörlerde video bulunamadı!${RESET}"
            rm -f "$VIDEO_LISTESI"; sleep 2; continue
        fi

        clear
        echo -e "${CYAN}=========================================${RESET}"
        echo -e "${CYAN}         DÖNÜŞTÜRME BAŞLIYOR${RESET}"
        echo -e "${CYAN}=========================================${RESET}"
        echo -e "  Kaynak : ${GREEN}${SON_MP3_KAYNAK}${RESET}"
        echo -e "  Kalite : ${GREEN}${MP3_KALITE}${RESET}"
        echo -e "  Çıktı  : ${GREEN}Video ile aynı klasör${RESET}"
        echo -e "  Toplam : ${GREEN}${toplam} video${RESET}"
        echo -e "${CYAN}-----------------------------------------${RESET}"

        basarili=0; hatali=0; atlanan=0; sayac=0

        while IFS= read -r video; do
            [[ -z "$video" ]] && continue
            sayac=$((sayac + 1))
            isim=$(basename "$video")
            isim_base="${isim%.*}"
            # MP3 videoyla aynı klasöre
            cikti_dosya="$(dirname "$video")/${isim_base}.mp3"

            if [[ -f "$cikti_dosya" ]]; then
                echo -e "${BLUE}→ Atlandı (zaten var):${RESET} ${isim_base}.mp3"
                ((atlanan++)); _ilerleme_goster "$sayac" "$toplam"; continue
            fi

            _ilerleme_goster "$sayac" "$toplam"

            if [[ -n "$VARSAYILAN_RESIM" && -f "$VARSAYILAN_RESIM" ]]; then
                ffmpeg -i "$video" -i "$VARSAYILAN_RESIM" \
                    -map 0:a:0 -map 1:0 \
                    -acodec libmp3lame -ab "$MP3_KALITE" -ar 44100 \
                    -metadata:s:v title="Album cover" \
                    -metadata:s:v comment="Cover (front)" \
                    "$cikti_dosya" -y -loglevel quiet 2>/dev/null
            else
                ffmpeg -i "$video" -vn \
                    -acodec libmp3lame -ab "$MP3_KALITE" -ar 44100 \
                    "$cikti_dosya" -y -loglevel quiet 2>/dev/null
            fi

            if [[ $? -eq 0 ]]; then
                echo -e "\n${GREEN}✓ Dönüştürüldü:${RESET} ${isim_base}.mp3"
                ((basarili++))
            else
                echo -e "\n${RED}✗ Hata:${RESET} $isim"
                ((hatali++)); rm -f "$cikti_dosya"
            fi
        done < "$VIDEO_LISTESI"

        rm -f "$VIDEO_LISTESI"
        echo -e "\n${MAGENTA}=========================================${RESET}"
        echo -e "${GREEN}✓ Başarılı : $basarili${RESET}"
        echo -e "${BLUE}→ Atlanan  : $atlanan${RESET}"
        echo -e "${RED}✗ Hatalı   : $hatali${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        read -p $'\nAna menüye dönmek için Enter...' _
        ana_menu; return
    done
}

# ─────────────────────────────────────────
# 6) MÜZİKLERE KAPAK RESMİ EKLE
# Dosya yerinde değişir — kopya kalmaz
# ─────────────────────────────────────────
muzik_kapak_menu() {
    while true; do
        clear
        echo -e "\n${CYAN}========================================${RESET}"
        echo -e "${CYAN}     Müziklere Kapak Resmi Ekle${RESET}"
        echo -e "${CYAN}========================================${RESET}"

        if [ -z "$VARSAYILAN_RESIM" ] || [ ! -f "$VARSAYILAN_RESIM" ]; then
            echo -e "  ${RED}HATA: Önce resim ayarını yapın! (Ana menü Seçenek 3)${RESET}"
            sleep 2; ana_menu; return
        fi
        echo -e "  ${GREEN}Kapak Resmi: $VARSAYILAN_RESIM${RESET}\n"

        echo -e "${YELLOW}[ Müzik Klasörü Seçin ]${RESET}"
        echo -e "  1) Dahili Depolama/Music"
        echo -e "  2) SD Kart"
        echo -e "  3) VidMate indirmeleri"
        echo -e "  4) SnapTube indirmeleri"
        echo -e "  5) Özel dizin belirt"
        if [ -n "$SON_MUZIK_KLASOR" ]; then
            echo -e "  ${GREEN}[Enter] Son kullanılan: $SON_MUZIK_KLASOR${RESET}"
        fi
        echo -e "  0) Ana Menüye Dön"
        read -p "Seçiminiz [0-5]: " muz_choice

        case "$muz_choice" in
            "")
                if [ -n "$SON_MUZIK_KLASOR" ]; then
                    MUZIK_KLASOR="$SON_MUZIK_KLASOR"
                else
                    echo -e "  ${RED}Kayıtlı klasör yok!${RESET}"; sleep 1; continue
                fi
                ;;
            1) MUZIK_KLASOR="/storage/emulated/0/Music" ;;
            2)
               SD_PATH=$(find /storage -maxdepth 1 -mindepth 1 ! -name "emulated" -type d 2>/dev/null | head -1)
               [[ -z "$SD_PATH" ]] && { echo -e "${RED}SD kart bulunamadı!${RESET}"; sleep 2; continue; }
               MUZIK_KLASOR="$SD_PATH"
               ;;
            3) MUZIK_KLASOR="/storage/emulated/0/VidMate/download" ;;
            4) MUZIK_KLASOR="/storage/emulated/0/snaptube/download/SnapTube Video" ;;
            5)
               read -p "Müzik dizin yolunu girin: " custom_muz
               [[ -z "$custom_muz" ]] && { echo -e "${RED}Boş bırakılamaz!${RESET}"; sleep 1; continue; }
               MUZIK_KLASOR="$custom_muz"
               ;;
            0) ana_menu; return ;;
            *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        if [ ! -d "$MUZIK_KLASOR" ]; then
            echo -e "  ${RED}HATA: Klasör bulunamadı: $MUZIK_KLASOR${RESET}"; sleep 2; continue
        fi

        echo -e "\n${YELLOW}Alt klasörler de taransın mı?${RESET}"
        echo -e "  1) Sadece bu klasör   2) Alt klasörler dahil"
        read -p "Seçiminiz [1-2]: " derinlik_sec
        [[ "$derinlik_sec" == "2" ]] && DERINLIK="" || DERINLIK="-maxdepth 1"

        SON_MUZIK_KLASOR="$MUZIK_KLASOR"
        _kaydet_ayarlar

        MUZIK_LISTESI="$HOME/.muzik_kapak_tmp.txt"
        find "$MUZIK_KLASOR" $DERINLIK -type f \
            \( -iname "*.mp3" -o -iname "*.m4a" -o -iname "*.aac" \
               -o -iname "*.flac" -o -iname "*.ogg" \) > "$MUZIK_LISTESI"

        toplam=$(wc -l < "$MUZIK_LISTESI")
        if [[ "$toplam" -eq 0 ]]; then
            echo -e "${RED}  Bu klasörde müzik dosyası bulunamadı!${RESET}"
            rm -f "$MUZIK_LISTESI"; sleep 2; continue
        fi

        clear
        echo -e "${CYAN}=========================================${RESET}"
        echo -e "${CYAN}       KAPAK EKLEME BAŞLIYOR${RESET}"
        echo -e "${CYAN}=========================================${RESET}"
        echo -e "  Klasör : ${GREEN}$MUZIK_KLASOR${RESET}"
        echo -e "  Resim  : ${GREEN}$VARSAYILAN_RESIM${RESET}"
        echo -e "  Toplam : ${GREEN}$toplam müzik${RESET}"
        echo -e "  Not    : ${CYAN}Dosyalar yerinde değiştirilir${RESET}"
        echo -e "${CYAN}-----------------------------------------${RESET}"

        basarili=0; hatali=0; sayac=0

        while IFS= read -r muzik; do
            [[ -z "$muzik" ]] && continue
            sayac=$((sayac + 1))
            isim=$(basename "$muzik")
            uzanti="${isim##*.}"
            klasor=$(dirname "$muzik")

            _ilerleme_goster "$sayac" "$toplam"

            # Gizli temp dosya — aynı klasörde
            temp_muzik="$klasor/.tmp_kapak_$$_${sayac}.${uzanti}"

            case "${uzanti,,}" in
                mp3)
                    ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" \
                        -map 0:a:0 -map 1:0 -acodec copy \
                        -metadata:s:v title="Album cover" \
                        -metadata:s:v comment="Cover (front)" \
                        "$temp_muzik" -y -loglevel quiet 2>/dev/null
                    ;;
                m4a|aac)
                    ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" \
                        -map 0:a:0 -map 1:0 -acodec copy \
                        -disposition:v:0 attached_pic \
                        "$temp_muzik" -y -loglevel quiet 2>/dev/null
                    ;;
                flac)
                    ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" \
                        -map 0 -map 1:0 -acodec copy \
                        -disposition:v:0 attached_pic \
                        "$temp_muzik" -y -loglevel quiet 2>/dev/null
                    ;;
                *)
                    ffmpeg -i "$muzik" -i "$VARSAYILAN_RESIM" \
                        -map 0:a:0 -map 1:0 -acodec copy \
                        "$temp_muzik" -y -loglevel quiet 2>/dev/null
                    ;;
            esac

            if [[ $? -eq 0 ]]; then
                # Başarılı: temp → orijinalin üstüne yaz
                mv "$temp_muzik" "$muzik"
                echo -e "\n${GREEN}✓ Kapak eklendi:${RESET} $isim"
                ((basarili++))
            else
                rm -f "$temp_muzik"
                echo -e "\n${RED}✗ Hata:${RESET} $isim"
                ((hatali++))
            fi
        done < "$MUZIK_LISTESI"

        rm -f "$MUZIK_LISTESI"
        echo -e "\n${MAGENTA}=========================================${RESET}"
        echo -e "${GREEN}✓ Başarılı : $basarili${RESET}"
        echo -e "${RED}✗ Hatalı   : $hatali${RESET}"
        echo -e "${MAGENTA}=========================================${RESET}"
        read -p $'\nAna menüye dönmek için Enter...' _
        ana_menu; return
    done
}

# ─────────────────────────────────────────
# 4) DOSYA YENİDEN ADLANDIRMA
# ─────────────────────────────────────────
adlandirma_menu() {
    while true; do
        clear
        echo -e "\n${CYAN}========================================${RESET}"
        echo -e "${CYAN}       Klasör Seçimi Menüsü${RESET}"
        echo -e "${CYAN}========================================${RESET}"
        echo -e "${YELLOW}1) VidMate indirilenleri işle${RESET}"
        echo -e "${YELLOW}2) SnapTube indirilenleri işle${RESET}"
        echo -e "${YELLOW}3) VidMate & SnapTube birlikte${RESET}"
        echo -e "${YELLOW}4) Telegram videolarını işle${RESET}"
        echo -e "${YELLOW}5) Tüm müzikler${RESET}"
        echo -e "${YELLOW}6) Özel dizin belirt${RESET}"
        echo -e "${YELLOW}0) Ana Menüye Dön${RESET}"
        read -p "Seçiminiz [0-6]: " choice

        case "$choice" in
            1) DIRS=("/storage/emulated/0/VidMate/download"); MODE_TYPE="video" ;;
            2) DIRS=("/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            3) DIRS=("/storage/emulated/0/VidMate/download" "/storage/emulated/0/snaptube/download/SnapTube Video"); MODE_TYPE="video" ;;
            4) DIRS=("/storage/emulated/0/Android/media/org.telegram.messenger/Telegram/Telegram Video"); MODE_TYPE="video" ;;
            5) MODE_TYPE="music" ;;
            6) read -p "Özel dizin yolunu girin: " custom_dir; DIRS=("$custom_dir"); MODE_TYPE="video" ;;
            0) ana_menu; return ;;
            *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        echo -e "\n${CYAN}--- İşlem Modu ---${RESET}"
        echo -e "${YELLOW}1) Prefix ekle  2) Metin kaldır  0) Ana Menü${RESET}"
        read -p "Seçiminiz [0-2]: " op_mode
        case "$op_mode" in
            1) MODE_OP="add" ;;
            2) MODE_OP="remove" ;;
            0) ana_menu; return ;;
            *) echo -e "${RED}Geçersiz seçim!${RESET}"; sleep 1; continue ;;
        esac

        if [[ "$MODE_OP" == "add" ]]; then
            echo -e "${GREEN}Prefix: $PREFIX${RESET}"
        else
            read -p "Kaldırılacak metni girin: " text_to_remove
            [[ -z "$text_to_remove" ]] && { echo -e "${RED}Hiç metin girilmedi!${RESET}"; sleep 1; continue; }
        fi

        processed=0; skipped=0; failed=0
        LOG_FILE="$HOME/process_log.txt"
        echo "Başlatma: $(date)" > "$LOG_FILE"

        process_file(){
            local f="$1" base="$(basename "$1")"
            case "$base" in *.nomedia|*.txt|*.json)
                ((skipped++)); return ;; esac
            if [[ "$MODE_OP" == "add" ]]; then
                [[ "$base" == "$PREFIX"* ]] && { ((skipped++)); return; }
                mv -- "$f" "$(dirname "$f")/$PREFIX$base" && ((processed++)) || ((failed++))
            else
                [[ "$base" != *"$text_to_remove"* ]] && { ((skipped++)); return; }
                local cleaned="${base//$text_to_remove/}"
                local target="$(dirname "$f")/$cleaned"
                [[ -z "$cleaned" || "$target" == "$f" ]] && { ((skipped++)); return; }
                mv -- "$f" "$target" && ((processed++)) || ((failed++))
            fi
        }

        if [[ "$MODE_TYPE" == "video" ]]; then
            for d in "${DIRS[@]}"; do
                echo -e "\n${CYAN}--- Tarama: $d ---${RESET}"
                while IFS= read -r -d '' file; do process_file "$file"; done \
                    < <(find "$d" -maxdepth 1 -type f -print0)
            done
        else
            while IFS= read -r -d '' file; do process_file "$file"; done \
                < <(find /storage/emulated/0 \
                    -path "*/Android/data" -prune -o \
                    -path "*/Android/obb" -prune -o \
                    -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.m4a" \
                    -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.ogg" \) -print0)
        fi

        echo -e "\n${MAGENTA}========================================${RESET}"
        echo -e "${GREEN}✓ İşlenen: $processed  ${BLUE}→ Atlanan: $skipped  ${RED}✗ Hatalı: $failed${RESET}"
        echo -e "${MAGENTA}========================================${RESET}"
        read -p $'\nAna menüye dönmek için Enter...' _
        ana_menu; return
    done
}
# ─────────────────────────────────────────
# ANA MENÜ
# ─────────────────────────────────────────
ana_menu() {
    clear
    echo "========================================="
    echo "      KAPAK DEĞİŞTİRİCİ (HAFIZALI)      "
    echo "========================================="
    echo "  Resim      : ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
    echo "  Son Kapak  : ${SON_KAPAK_KLASOR:-'Henüz yok'}"
    echo "  Son MP3    : ${SON_MP3_KAYNAK:-'Henüz yok'}"
    echo "  Son Müzik  : ${SON_MUZIK_KLASOR:-'Henüz yok'}"
    echo "-----------------------------------------"
    echo "  1 - Video Kapağını Değiştir + Prefix Ekle"
    echo "  2 - Hafızayı Sil"
    echo "  3 - Resim Ayarını Değiştir"
    echo "  4 - Dosya Yeniden Adlandır"
    echo "  5 - Video → MP3 Dönüştür"
    echo "  6 - Müziklere Kapak Resmi Ekle"
    echo "  7 - Çıkış"
    echo "========================================="
    read -p "Seçiminiz: " secim

    case $secim in
        1) kapak_degistir_isle ;;
        2)
            read -p "  Emin misiniz? (e/h): " onay
            [[ "$onay" == "e" || "$onay" == "E" ]] && {
                rm -f "$ISLENENLER_LISTESI" && touch "$ISLENENLER_LISTESI"
                echo "  Hafıza silindi."
            } || echo "  İptal edildi."
            sleep 1; ana_menu
            ;;
        3)
            echo ""
            echo "  Mevcut resim: ${VARSAYILAN_RESIM:-'Ayarlanmamış'}"
            read -p "  Yeni Resim Tam Yolu (boş = değişmez): " yeni_r
            if [ -n "$yeni_r" ]; then
                [ -f "$yeni_r" ] && { VARSAYILAN_RESIM="$yeni_r"; _kaydet_ayarlar; echo "  Resim güncellendi."; } \
                                 || echo "  HATA: Dosya bulunamadı."
            else
                echo "  Değişiklik yapılmadı."
            fi
            sleep 1; ana_menu
            ;;
        4) adlandirma_menu ;;
        5) mp3_donustur_menu ;;
        6) muzik_kapak_menu ;;
        7) echo "  Çıkılıyor..."; exit 0 ;;
        *) echo "  Geçersiz seçim!"; sleep 1; ana_menu ;;
    esac
}

ana_menu
EOF
chmod +x ~/Video-kapak-resim-de-i-tirme/kapak_degistir.sh
echo "Güncellendi!"
