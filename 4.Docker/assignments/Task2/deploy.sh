MY_HOSTS="172.20.10.2 192.168.2.158"

####################
# Making Deploy Dir
####################

mkdir deploy
cd deploy

#########################################
# Prepare ansible conf files and playbook 
#########################################

#ansible-config init --disabled -t all > ansible.cfg

# configure ansible.cfg
cat <<EOF > ansible.cfg
[defaults]
host_key_checking = False
EOF

#adding my hosts 

cat <<EOF > inventory.ini
[servers]
$(for host in $MY_HOSTS; do echo $host; done)
EOF

# Creating Playbook
cat <<EOF > deploy.yml
---
- name: Managed Docker Installation
  hosts: all
  become: true

  tasks:

  ###################################################
  # installing docker and configure the user
  ###################################################

    - name: Ensure Curl is installed (Prerequisite)
      ansible.builtin.apt:
        name: curl
        state: present
        update_cache: yes

    - name: Notify service status
      ansible.builtin.debug:
        msg: "Curl is ok "

    - name: Ensure Python Docker library is installed
      ansible.builtin.apt:
        name: python3-docker
        state: present

    - name: Notify service status
      ansible.builtin.debug:
        msg: "Python is ok "


  # this to gather all packages and compare if docker installed or not :D
    - name: Gather package facts
      ansible.builtin.package_facts:
        manager: auto

    - name: Install Docker if not present
      block:
        - name: Download Docker convenience script
          ansible.builtin.get_url:
            url: https://get.docker.com
            dest: /tmp/get-docker.sh
            mode: '0755'

        - name: Execute Docker installation script
          ansible.builtin.command: /tmp/get-docker.sh
          register: docker_install_result
          changed_when: "'installed' in docker_install_result.stdout"

        - name: Add current user to Docker group
          ansible.builtin.user:
            name: "{{ ansible_user | default(lookup('env', 'USER')) }}"
            groups: docker
            append: yes

        - name: Remove the installation script
          ansible.builtin.file:
            path: /tmp/get-docker.sh
            state: absent

      #this line is a condition that veifry if docker installed or not
      when: "'docker-ce' not in ansible_facts.packages"

    - name: Verify Docker service is running
      ansible.builtin.service:
        name: docker
        state: started
        enabled: yes

    - name: Notify service status
      ansible.builtin.debug:
        msg: "Docker service has been verified and is currently running."


  ###################################################
  # Pull the image and run it
  ###################################################

    - name: Pull Todo-app
      community.docker.docker_image:
        name: ahmedhoss/todo-app
        source: pull
        tag: "39a32f3"

    - name: Pull mongo
      community.docker.docker_image:
        name: mongo
        source: pull
        tag: "6.0"
    

    - name: Notify service status
      ansible.builtin.debug:
        msg: "images are ready"

    - name: Create dedicated network
      community.docker.docker_network:
        name: todo_network

    - name: Run DB container
      community.docker.docker_container:
        name: mongo
        image: mongo:6.0
        state: started
        networks:
          - name: todo_network
        #Container restart if failed 
        restart_policy: always
        published_ports:
          - "27017:27017"

    - name: Wait for 1 minute until the DB UP
      ansible.builtin.pause:
        seconds: 60

    - name: Run container
      community.docker.docker_container:
        name: Todo-app
        image: ahmedhoss/todo-app:39a32f3
        networks:
          - name: todo_network
        env:
          # Ensure the app knows where to find the DB
          MONGO_URL: "mongodb://mongo:27017/todo" 
        state: started
        restart_policy: always #Container restart if failed 
        published_ports:
          - "3000:8080"  # Maps host port 80 to container port 80

    # - name: Check website result (Wait for 200 OK)
    #   ansible.builtin.uri:
    #     url: "http://localhost:3000"
    #     status_code: 200
    #   register: website_result
    #   until: website_result.status == 200
    #   retries: 2      # Retry 2 times
    - name: Verify website and capture content
      ansible.builtin.uri:
        url: "http://localhost:3000"
        return_content: yes
        status_code: 200
      register: web_content
      until: web_content.status == 200
      retries: 2
      delay: 5

    - name: Display first 2 lines of website content
      ansible.builtin.debug:
        msg: "{{ web_content.content.splitlines()[:10] }}"



EOF

#########################################
# Play the Playbook :D
#########################################
ansible-playbook -i inventory.ini deploy.yml
