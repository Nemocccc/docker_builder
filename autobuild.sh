#!/bin/bash
#author: nemo
#version: 0.4
#date: 2024/09/28


SCRIPT_DIR=$(pwd)    #TODO not a good solution


Dockerfile_maker() {
    echo "Initializing..."
    touch Dockerfile

	while true;
	do
	    echo """
	    Input image layers you want (in order, split by , or space)
		a -> default base_image and workspace
		b -> use my own blocks
		c -> add some blocks
		d -> delete some blocks
		1 -> basic tools (include: git)
		2 -> python
		3 -> cpp essential
		4 -> rust
	    """
	    read -r choices
	    local -a choices_a=(${choices//,/ })
	
	    for c in "${choices_a[@]}"; 
		do
	        case $c in
				'a')
				    echo "FROM ubuntu:22.04" > Dockerfile
					echo "" >> Dockerfile
				    echo "WORKDIR /workspace" >> Dockerfile
				    echo "" >> Dockerfile
					;;
				'b')
					while true;
					do
						bash ${SCRIPT_DIR}/get_blocks.sh "${SCRIPT_DIR}"
						read -p " continue? (y|N) : " if_continue
						if [[ $if_continue != 'y' ]];
						then
							echo " stop "
							break
						fi
					done
					;;
				'c')
					while true;
					do
						bash ${SCRIPT_DIR}/add_blocks.sh "${SCRIPT_DIR}"
						read -p " continue? (y|N) : " if_continue
						if [[ $if_continue != 'y' ]];
						then
							echo " stop "
							break
						fi
					done
					;;
				'd')
					while true;
					do
						bash ${SCRIPT_DIR}/delete_blocks.sh "${SCRIPT_DIR}"
						read -p " continue? (y|N) : " if_continue
						if [[ $if_continue != 'y' ]];
						then
							echo " stop "
							break
						fi
					done
					;;
	            1)
	                cat <<'EOF' >> Dockerfile
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
EOF
	                echo "" >> Dockerfile
	                ;;
	            2)
	                cat <<'EOF' >> Dockerfile
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-pip \
    && pip3 install --upgrade pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
EOF
	                echo "" >> Dockerfile
	
	                read -rp "Do you have requirements.txt for python? (y|N) " require
	                if [[ $require == "y" ]]; 
					then
	                    cat <<'EOF' >> Dockerfile
COPY requirements.txt .
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip3 install --no-cache-dir -r requirements.txt
EOF
	                    echo "" >> Dockerfile
	                fi
	                ;;
	            3)
	                cat <<'EOF' >> Dockerfile
RUN set -ex \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
EOF
	                echo "" >> Dockerfile
	                ;;
	            4)
	                cat <<'EOF' >> Dockerfile
RUN set -ex \
    && apt-get update \
    && curl -sSf https://sh.rustup.rs | sh -s -- -y \
    && rustup update \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
EOF
	                echo "" >> Dockerfile
	                ;;
	            *)
	                echo "Invalid choice."
	                ;;
	        esac
	    done
		read -p "that's all? we gonna finish the Dockerfile (y|N)" if_enough
		if [[ $if_enough == 'y' ]];
		then
			break
		fi
	done
}

docker_compose_maker() {
    local image_name=$1
    cd .. && mkdir workspace && cd config
    touch docker-compose.yml
	# TODO diy_docker_compose.sh
	#read -p "use default settings?(y|N)" if_default
	#if [[ if_default == 'y' ]];
	#then
	cat <<EOF > docker-compose.yml
version: '3'
services:
  ${image_name}:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: ${image_name}
    init: true
    ports:
      - "8080:80"
    network_mode: host
    ipc: host
    restart: always
    privileged: true
    tty: true
    shm_size: 268M
    volumes:
      - ../workspace:/workspace
EOF
	#else
}

docker_builder() {
    local dir_name=$1
	# TODO or we can appoint the dir to store project.
	mkdir -p ~/workspace
    cd ~/workspace
    if [[ -d "$dir_name" ]]; 
	then
        echo "$dir_name is already exists. Cover it? (y|N)"
        while true; 
		do
            read -rp "Enter your choice: " cover_or_not
            if [[ $cover_or_not == "y" ]]; 
			then
                rm -r "$dir_name"
                mkdir -p "$dir_name" && cd "$dir_name"
                mkdir config && cd config
                Dockerfile_maker
                docker_compose_maker "$dir_name"
                echo "Build finished"
                break
            elif [[ $cover_or_not == "N" ]]; then
                echo "Script exits"
                exit 0
            else
                echo "Illegal input, try again."
            fi
        done
    else
        mkdir -p "$dir_name" && cd "$dir_name"
        mkdir config && cd config
        Dockerfile_maker
        docker_compose_maker "$dir_name"
        echo "Build finished"
    fi
}


start_docker() {
	read -p "start docker right now?(y|N) : " start_or_not
	if [[ $start_or_not == y ]];
	then
		local image_name=$1
		echo "${pwd}"
		docker-compose build
		if [[ $? == 0 ]];
		then
			docker-compose up -d
			docker exec -it ${image_name}_ubuntu22 bash
		fi
	fi
}

while true; 
do
    echo """
    Input your requirements:
    1 -> Copy Docker files.
    """

    read -rp "Enter your choice: " number
    case $number in
        1)
            read -rp "Enter the name of your new project (new directory in ~ dir): " dir_name
            docker_builder "$dir_name"
			start_docker "$dir_name"
            break
            ;;
        *)
            echo "Illegal input, enter valid value."
            ;;
    esac
done
