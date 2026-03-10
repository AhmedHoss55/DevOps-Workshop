# Funtion to print the steps with color 
Print() {
    # Color Codes
    local CYAN='\033[0;36m'
    local BOLD='\033[1;37m'
    local NC='\033[0m' # No Color (Reset)

    local msg="$1"
    local edge=$(echo "$msg" | sed 's/./#/g')

    echo -e "${CYAN}${edge}"
    echo -e "${msg}"
    echo -e "${CYAN}${edge}${NC}"
}

# Funtion to print the result with green color 
Sucess() {
    # Color Codes
    local CYAN='\033[0;32m'
    local BOLD='\033[1;37m'
    local NC='\033[0m' # No Color (Reset)

    local msg="Done ✅"
    local edge=$(echo "$msg" | sed 's/./#/g')

    echo -e "${CYAN}${edge}"
    echo -e "${msg}"
    echo -e "${CYAN}${edge}${NC}"
}

# Function to install missing apps
install_app() {
    case $1 in
        "git")
            echo "Installing Git..."
            sudo apt update && sudo apt install -y git
            ;;
        "docker")
            echo "Installing Docker..."
            # Using the official Docker convenience script for 2026
            curl -fsSL https://get.docker.com -o get-docker.sh
            sudo sh get-docker.sh
            sudo usermod -aG docker $USER
            rm get-docker.sh
            ;;
        "ansible")
            echo "Installing Ansible..."
            sudo apt update
            sudo apt install -y software-properties-common
            sudo add-apt-repository --yes --update ppa:ansible/ansible
            sudo apt install -y ansible
            ;;
    esac
}

# Function to virify if apps installed or not
verify_and_install() {
    local apps=("git" "docker" "ansible")

    for app in "${apps[@]}"; do
        if command -v "$app" &> /dev/null; then
            echo "[BYPASS] $app is already installed."
        else
            echo "[NOT FOUND] $app is missing."
            install_app "$app"
        fi
    done
}



Print "Checking installed apps"
verify_and_install
Sucess 
sleep 3


Print "Making working dir"
mkdir todo-app
cd todo-app
Sucess 
sleep 3

Print "cloning the app" 
git clone https://github.com/AhmedHoss55/node-todo.git
Sucess
sleep 3

Print "create docker network" 
docker network create todo-network
Sucess
sleep 3

Print "delete all containers"
docker stop $(docker ps -q) 2>/dev/null # 2>/dev/null to hide the error if list is empty
docker container prune -f
Sucess
sleep 3


Print "running mongodb container" 
docker run -d --name mongo --network todo-network -p 27017:27017 mongo:6.0
Sucess
sleep 20

Print "configure db file" 
cat << EOF > /home/chips/todo-app/node-todo/config/database.js
module.exports = {
    localUrl: 'mongodb://mongo:27017/todo-db'
};
EOF
Sucess
sleep 3

Print "Create docker file"
cat << EOF > /home/chips/todo-app/node-todo/Dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
# to just install required prod lib
RUN npm install --production
#copy code
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF

Sucess
sleep 3

Print "Build docker image"
cd /home/chips/todo-app/node-todo
docker build -t todo-app:v1 .
Sucess
sleep 3

Print "run docker file"
docker run -d --name todo -p 3000:8080 --network todo-network todo-app:v1
Sucess
sleep 3

Print "Smoke Testing"
curl -Is 127.0.0.1:3000 | head -n 1 # do the curl and show the stauts
Sucess
sleep 3

Print "Change image tag"
COMMIT_ID=$(git rev-parse --short HEAD) # store the firts 7 chars of last commit into variable COMMIT_ID ;) 
docker tag todo-app:v1 ahmedhoss/todo-app:$COMMIT_ID
Sucess
sleep 3

Print "Pushing the image"
docker push ahmedhoss/todo-app:$COMMIT_ID
Sucess
sleep 3
