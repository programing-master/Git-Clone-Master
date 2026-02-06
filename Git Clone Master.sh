
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

mostrar_titulo() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          CLONADOR DE REPOSITORIOS                    ║"
    echo "║    (Crea + Sincroniza + Pull en cada rama)           ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

sincronizar_todas_las_ramas() {
    local directorio="$1"
    
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🔄 CREANDO Y SINCRONIZANDO TODAS LAS RAMAS${NC}"
    echo ""
    
    cd "$directorio" || {
        echo -e "${RED}✗ No se pudo acceder a $directorio${NC}"
        return 1
    }
    
    echo -e "${CYAN}📍 Ubicación actual: $(pwd)${NC}"
    echo ""
    
    # 1. CONFIGURAR PARA TRAER TODAS LAS RAMAS
    echo -e "${CYAN}1. Configurando para traer todas las ramas...${NC}"
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    
    # 2. HACER FETCH
    echo -e "${CYAN}2. Descargando información de ramas remotas...${NC}"
    git fetch --all --prune
    
    # 3. OBTENER LISTA DE RAMAS REMOTAS
    echo -e "${CYAN}3. Obteniendo lista de ramas remotas...${NC}"
    local ramas_remotas=$(git branch -r | grep -v '\->' | grep -v 'HEAD' | sed 's/^[[:space:]]*//')
    
    if [[ -z "$ramas_remotas" ]]; then
        echo -e "${YELLOW}⚠ No se encontraron ramas remotas${NC}"
        return 0
    fi
    
    echo ""
    echo -e "${GREEN}🌐 Ramas remotas encontradas:${NC}"
    echo "$ramas_remotas"
    echo ""
    
    # 4. PROCESAR CADA RAMA REMOTA
    echo -e "${CYAN}4. Procesando cada rama remota...${NC}"
    echo ""
    
    local contador_creadas=0
    local contador_sincronizadas=0
    local rama_original=$(git branch --show-current 2>/dev/null)
    
    # Guardar lista de ramas para procesar después
    declare -a ramas_a_procesar=()
    
    while IFS= read -r rama_remota; do
        [[ -z "$rama_remota" ]] && continue
        
        # Extraer nombre de rama (sin origin/)
        local nombre_rama="${rama_remota#origin/}"
        
        # Saltar si es HEAD
        if [[ "$nombre_rama" == "HEAD" ]]; then
            continue
        fi
        
        echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
        echo -e "${MAGENTA}📦 Procesando rama: $nombre_rama${NC}"
        
        # Verificar si ya existe localmente
        if git show-ref --verify --quiet "refs/heads/$nombre_rama" 2>/dev/null; then
            echo -e "  ✅ Ya existe localmente"
            
            # Sincronizar rama existente
            echo -n "  ↳ Cambiando a rama... "
            if git checkout "$nombre_rama" 2>/dev/null; then
                echo -e "${GREEN}✓${NC}"
                echo -n "  ↳ Haciendo pull para sincronizar... "
                if git pull origin "$nombre_rama" 2>/dev/null; then
                    echo -e "${GREEN}✓ Sincronizada${NC}"
                    ((contador_sincronizadas++))
                else
                    echo -e "${YELLOW}⚠ Error en pull${NC}"
                    echo -n "  ↳ Intentando con --allow-unrelated-histories... "
                    if git pull origin "$nombre_rama" --allow-unrelated-histories 2>/dev/null; then
                        echo -e "${GREEN}✓ Sincronizada (con flag)${NC}"
                        ((contador_sincronizadas++))
                    else
                        echo -e "${RED}✗ Falló${NC}"
                    fi
                fi
            else
                echo -e "${RED}✗ No se pudo cambiar${NC}"
            fi
            
        else
            # Crear nueva rama local
            echo -n "  ↳ Creando rama local... "
            
            # Método 1: Intentar con checkout -b
            if git checkout -b "$nombre_rama" "$rama_remota" 2>/dev/null; then
                echo -e "${GREEN}✓ Creada${NC}"
                echo -n "  ↳ Haciendo pull para asegurar sincronización... "
                git pull origin "$nombre_rama" 2>/dev/null && echo -e "${GREEN}✓ Sincronizada${NC}"
                ((contador_creadas++))
                
            else
                # Método 2: Usar fetch con refspec
                echo -n "(método alternativo)... "
                if git fetch origin "$nombre_rama:$nombre_rama" 2>/dev/null; then
                    echo -e "${GREEN}✓ Creada${NC}"
                    echo -n "  ↳ Cambiando a rama... "
                    if git checkout "$nombre_rama" 2>/dev/null; then
                        echo -e "${GREEN}✓${NC}"
                        echo -n "  ↳ Haciendo pull... "
                        git pull origin "$nombre_rama" 2>/dev/null && echo -e "${GREEN}✓ Sincronizada${NC}"
                        ((contador_creadas++))
                    else
                        echo -e "${RED}✗ No se pudo cambiar${NC}"
                    fi
                else
                    echo -e "${RED}✗ No se pudo crear${NC}"
                fi
            fi
        fi
        
        # Agregar a lista para verificar después
        ramas_a_procesar+=("$nombre_rama")
        
    done <<< "$ramas_remotas"
    
    # 5. VOLVER A RAMA ORIGINAL O MAIN/MASTER
    echo ""
    echo -e "${CYAN}5. Volviendo a rama original...${NC}"
    
    if [[ -n "$rama_original" ]]; then
        git checkout "$rama_original" 2>/dev/null && echo -e "  ✅ Volviendo a: $rama_original"
    else
        if git checkout main 2>/dev/null; then
            echo -e "  ✅ Cambiado a: main"
        elif git checkout master 2>/dev/null; then
            echo -e "  ✅ Cambiado a: master"
        else
            echo -e "  ⚠️  No se pudo cambiar a rama principal"
        fi
    fi
    
    # 6. MOSTRAR RESUMEN COMPLETO
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📊 RESUMEN COMPLETO${NC}"
    echo ""
    
    echo -e "  ${MAGENTA}• Directorio actual:${NC} $(pwd)"
    echo -e "  ${MAGENTA}• Rama actual:${NC} $(git branch --show-current 2>/dev/null)"
    echo -e "  ${MAGENTA}• Ramas remotas detectadas:${NC} $(echo "$ramas_remotas" | wc -l)"
    echo -e "  ${MAGENTA}• Ramas locales creadas:${NC} $contador_creadas"
    echo -e "  ${MAGENTA}• Ramas sincronizadas:${NC} $contador_sincronizadas"
    
    # 7. MOSTRAR ESTADO FINAL DE RAMAS
    echo ""
    echo -e "${CYAN}🌳 ESTADO FINAL DE RAMAS:${NC}"
    echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
    
    echo -e "${GREEN}📍 Ramas locales:${NC}"
    git branch --color=always
    
    echo ""
    echo -e "${GREEN}🌐 Ramas remotas:${NC}"
    git branch -r
    
    echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
    
    # 8. VERIFICAR QUE LAS RAMAS TIENEN CONTENIDO
    echo ""
    echo -e "${CYAN}🔍 VERIFICANDO CONTENIDO DE RAMAS:${NC}"
    echo ""
    
    for rama in "${ramas_a_procesar[@]}"; do
        echo -n "  📁 $rama - "
        # Cambiar temporalmente a la rama para verificar
        if git checkout "$rama" 2>/dev/null; then
            # Contar archivos (excluyendo .git)
            local num_archivos=$(find . -type f ! -path "./.git/*" 2>/dev/null | wc -l)
            local num_carpetas=$(find . -type d ! -path "./.git" ! -path "./.git/*" 2>/dev/null | wc -l)
            echo -e "Archivos: ${GREEN}$num_archivos${NC}, Carpetas: ${GREEN}$num_carpetas${NC}"
            # Volver a rama anterior temporal
            git checkout - 2>/dev/null >/dev/null
        else
            echo -e "${RED}No accesible${NC}"
        fi
    done
    
    # Volver a rama principal final
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
    
    echo ""
    echo -e "${GREEN}✅ Proceso de sincronización completado${NC}"
    
    return 0
}

# Función principal
main() {
    mostrar_titulo
    
    # PEDIR URL
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}PASO 1: URL del repositorio${NC}"
    echo ""
    
    local url_repo=""
    
    while true; do
        echo -en "${YELLOW}👉 Ingresa la URL del repositorio: ${NC}"
        read url_repo
        
        # Asegurar .git
        if [[ ! "$url_repo" =~ \.git$ ]]; then
            url_repo="${url_repo}.git"
        fi
        
        if [[ -z "$url_repo" ]]; then
            echo -e "${RED}✗ La URL no puede estar vacía${NC}"
            continue
        fi
        
        echo -e "${CYAN}URL: ${MAGENTA}$url_repo${NC}"
        
        read -p "¿Es correcta? (s/n): " confirmar
        if [[ "$confirmar" == "s" ]] || [[ "$confirmar" == "S" ]]; then
            break
        fi
        echo ""
    done
    
    # DIRECTORIO DESTINO
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}PASO 2: Directorio de destino${NC}"
    echo ""
    
    local nombre_default=$(basename "$url_repo" .git)
    echo -e "${CYAN}Nombre sugerido: ${MAGENTA}$nombre_default${NC}"
    echo ""
    
    local directorio_destino=""
    echo -en "${YELLOW}👉 Directorio destino (Enter para '$nombre_default'): ${NC}"
    read directorio_destino
    
    [[ -z "$directorio_destino" ]] && directorio_destino="$nombre_default"
    
    RUTA_COMPLETA="$(pwd)/$directorio_destino"
    echo -e "${CYAN}Ruta completa: ${MAGENTA}$RUTA_COMPLETA${NC}"
    
    # Verificar si existe
    if [[ -d "$directorio_destino" ]]; then
        echo -e "${YELLOW}⚠ El directorio ya existe.${NC}"
        read -p "¿Eliminarlo? (s/n): " eliminar
        if [[ "$eliminar" == "s" ]]; then
            rm -rf "$directorio_destino"
            echo -e "${GREEN}✓ Eliminado${NC}"
        else
            echo -e "${YELLOW}Operación cancelada${NC}"
            exit 0
        fi
    fi
    
    # CONFIRMAR
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}PASO 3: Confirmación${NC}"
    echo ""
    
    echo -e "${CYAN}¿Clonar y sincronizar todas las ramas?${NC}"
    echo -e "  • URL: $url_repo"
    echo -e "  • Directorio: $directorio_destino"
    echo ""
    
    read -p "¿Continuar? (s/n): " confirmar_final
    if [[ "$confirmar_final" != "s" ]]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
    fi
    
    # CLONAR
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}🚀 CLONANDO REPOSITORIO...${NC}"
    echo ""
    
    git clone "$url_repo" "$directorio_destino"
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}✗ Error al clonar${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Clonación completada${NC}"
    
    # SINCRONIZAR RAMAS
    sincronizar_todas_las_ramas "$directorio_destino"
    
    # MOSTRAR CONTENIDO
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📂 CONTENIDO DEL PROYECTO:${NC}"
    echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
    
    if cd "$directorio_destino" 2>/dev/null; then
        echo -e "${CYAN}Directorio: $(pwd)${NC}"
        echo ""
        
        # Mostrar archivos principales
        echo -e "${YELLOW}Archivos principales:${NC}"
        ls -la | grep -v "^total" | head -10
        
        # Mostrar estructura básica
        echo ""
        echo -e "${YELLOW}Estructura de carpetas:${NC}"
        find . -type d ! -path "./.git" ! -path "./.git/*" | head -10 | sed 's/^/  /'
    else
        echo -e "${RED}No se pudo acceder al directorio${NC}"
    fi
    
    echo -e "${BLUE}──────────────────────────────────────────────────────${NC}"
    
    # COMANDOS ÚTILES
    echo ""
    echo -e "${CYAN}💡 COMANDOS PARA VERIFICAR:${NC}"
    echo -e "  ${YELLOW}cd \"$RUTA_COMPLETA\"${NC}"
    echo -e "  ${YELLOW}git branch -a                # Ver todas las ramas${NC}"
    echo -e "  ${YELLOW}git checkout develop         # Cambiar a rama develop${NC}"
    echo -e "  ${YELLOW}git log --oneline -5         # Ver últimos commits${NC}"
    echo -e "  ${YELLOW}git status                   # Ver estado actual${NC}"
    echo ""
    
    # VERIFICAR MANUALMENTE
    echo -e "${CYAN}🔍 VERIFICACIÓN MANUAL:${NC}"
    echo -e "Ejecuta estos comandos para verificar:"
    echo ""
    
    cat << 'EOF'
  cd "$directorio_destino"
  echo "=== RAMAS LOCALES ==="
  git branch
  echo ""
  echo "=== CONTENIDO DE develop ==="
  git checkout develop 2>/dev/null && ls -la
  echo ""
  echo "=== ÚLTIMOS COMMITS EN develop ==="
  git log --oneline -3
  git checkout main 2>/dev/null
EOF
    
    echo ""
    echo -e "${GREEN}✨ Proceso completado exitosamente!${NC}"
    echo ""
    echo -e "${YELLOW}Presiona Enter para salir...${NC}"
    read
}

main