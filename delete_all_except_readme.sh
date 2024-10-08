
#!/bin/bash

# === Configuratie ===

# Definieer de repositories die leeggemaakt moeten worden
REPOS=("https://github.com/hichmok93/blog.git" "https://github.com/hichmok93/moki.github.io.git")
README_FILE="README.md"

# === Functies ===

# Functie om te controleren of een commando bestaat
command_exists () {
    command -v "$1" >/dev/null 2>&1 ;
}

# Controleer of vereiste commando's geïnstalleerd zijn
for cmd in git; do
    if ! command_exists $cmd ; then
        echo "Error: $cmd is niet geïnstalleerd. Installeer $cmd en probeer opnieuw."
        exit 1
    fi
done

# === Stap 1: Loop door elke opgegeven repository ===
for REPO in "${REPOS[@]}"; do
    # Verkrijg de naam van de directory op basis van de URL
    REPO_DIR=$(basename "$REPO" .git)

    # Clone de repository als deze nog niet bestaat
    if [ ! -d "$REPO_DIR" ]; then
        echo "Clonen van repository: $REPO"
        git clone "$REPO"
    fi

    echo "----------------------------------------"
    echo "Verwerken van repository: $REPO_DIR"
    cd "$REPO_DIR" || { echo "Kan niet naar $REPO_DIR navigeren"; continue; }

    # Voer een pull uit om de laatste wijzigingen op te halen
    echo "Ophalen van de laatste wijzigingen..."
    git pull origin main || git pull origin master

    # Controleer of README.md bestaat
    if [ ! -f "$README_FILE" ]; then
        echo "Warning: $README_FILE bestaat niet in $REPO_DIR. Een lege README zal worden aangemaakt."
        echo "# $(basename "$REPO_DIR")" > "$README_FILE"
        git add "$README_FILE"
        git commit -m "Add $README_FILE"
    fi

    # Lijst alle bestanden behalve README.md
    FILES_TO_REMOVE=$(git ls-files | grep -v -i "^$README_FILE$")

    if [ -z "$FILES_TO_REMOVE" ]; then
        echo "Geen bestanden om te verwijderen in $REPO_DIR."
    else
        echo "Verwijderen van de volgende bestanden:"
        echo "$FILES_TO_REMOVE"

        # Verwijder de bestanden
        echo "$FILES_TO_REMOVE" | xargs git rm -f

        # Verwijder ongetrackte bestanden en directories
        git clean -fd

        # Commit de verwijderingen
        git commit -m "Remove all files except $README_FILE" || echo "Geen wijzigingen om te committen."
    fi

    # Push de wijzigingen naar de remote repository
    echo "Pushing wijzigingen naar remote repository..."
    git push origin main || git push origin master || echo "Kan niet pushen naar main of master branch."

    # Navigeer terug naar de bovenliggende directory
    cd .. || exit
done

echo "----------------------------------------"
echo "Alle opgegeven repositories zijn verwerkt."

