#!/usr/bin/env bash

# This script installs the needed scripts and tools for a Minecraft server running on Java

jreversion="$1"
jreminmem="$2"
jremaxmem="$3"
type="$4"
version="$5"
apt-get update
apt-get upgrade -y

# Installs base packages needed

apt-get install -y \
  tmux \
  openjdk-"$jreversion"-jre-headless \
  python3-pip

pip3 install -U requests fire

# Creates the minecraft user and the minecraft directory for minecraft installations

mkdir -p /minecraft

# Creates the eula.txt file which is needed in all Minecraft servers

cat <<EOF | tee /minecraft/eula.txt
#By changing the setting below to TRUE you are indicating your agreement to our EULA (https://account.mojang.com/documents/minecraft_eula).
#Thu Aug 08 00:00:00 UTC 2022
eula=true
EOF

# Creates the base whitelist json which includes users who are allowed onto the server by default

cat <<EOF | tee /minecraft/whitelist.json
[
  {
    "uuid": "af418ce7-53d4-4252-a4b3-c85bc341f014",
    "name": "KFCColonel"
  }
]
EOF

# Creates the base op json file which sets the desired users as server overlords

cat <<EOF | tee /minecraft/ops.json
[
  {
    "uuid": "af418ce7-53d4-4252-a4b3-c85bc341f014",
    "name": "KFCColonel",
    "level": 4,
    "bypassesPlayerLimit": false
  }
]
EOF

# Creates the systemd service file used to start and stop minecraft servers using tmux

cat <<EOF | tee /etc/systemd/system/minecraft.service
[Unit]
Description=Minecraft Server

[Service]
WorkingDirectory=/minecraft
User=minecraft
Type=forking
Restart=always

ExecStart=/usr/bin/tmux new-session -s mc-%i -d '/minecraft/start-server.sh'
ExecStop=/usr/bin/tmux send-keys -t mc-%i:0.0 'say SERVER SHUTTING DOWN. Saving map...' C-m 'save-all' C-m 'stop' C-m
ExecStop=/bin/sleep 2

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon
systemctl daemon-reload


# Unfortunately each minecraft server (especially modpacks) have completely different ways to go about installing the server packages (i.e forge vs vanilla, papermc vs spigot, etc.)
# We'll try to install a base if possible. If type is not set, leave blank

# Installs papermc for vanilla. The vanilla vanilla minecraft jar is pretty bad imo
if [ "$type" == "vanilla" ]; then
  build="$(curl https://api.papermc.io/v2/projects/paper/versions/$version/builds | jq -r '.builds[-1].build')"
  wget -O paper.jar "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar"
  mv paper.jar /minecraft/minecraft-server.jar
  # Start and stop the server to generate the server property files and whatnot
  cd /minecraft
  printf "%s" "stop" | java -jar minecraft-server.jar
  
  # Pre configure the server properties file
  sed -i 's/motd=.*/motd=NEEEEEEEEEEEEEEEEEEEEEE/g' server.properties
  sed -i 's/enable-command-block=false/enable-command-block=true/g' server.properties
  sed -i 's/white-list=false/white-list=true/g' server.properties
  sed -i 's/allow-flight=false/allow-flight=true/g' server.properties
  sed -i 's/enforce-whitelist=false/enforce-whitelist=true/g' server.properties
  sed -i 's/difficulty=.*/difficulty=normal/g' server.properties

  # Depending on what server version is used, modify the java arguments
  if [ "$jreversion" = "8" ]; then
    cat <<EOF | tee /minecraft/start-server.sh
    #!/usr/bin/env bash
    /usr/bin/java -jar -XX:+UseG1GC -Xmx${jremaxmem}G -Xms${jreminmem}G -Dfml.readTimeout=120 -Dsun.rmi.dgc.server.gcInterval=2147483646 -XX:+UnlockExperimentalVMOptions -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M minecraft-server.jar
EOF
  else
    cat <<EOF | tee /minecraft/start-server.sh
    #!/usr/bin/env bash
    /usr/bin/java -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dfml.readTimeout=180 -Dfml.queryResult=confirm -Xmx${jremaxmem}G -Xms${jreminmem}G -jar minecraft-server.jar
EOF
  fi
fi

if [ "$type" == "forge" ]; then
  forgeurl=$(python3 /tmp/get-forge-version.py --version="$version")
  wget -O forge-installer.jar "$forgeurl"
  mv forge-installer.jar /minecraft/forge-installer.jar
  pwd
  cd /minecraft
  java -jar forge-installer.jar --installServer
  rm -rf forge-installer.jar
  mv /minecraft/run.sh /minecraft/start-server.sh

  echo "-Xmx${jremaxmem}G" >> user_jvm_args.txt
  echo "-Xms${jreminmem}G" >> user_jvm_args.txt

  # Start and stop the server to generate the server property files and whatnot
  printf "%s" "stop" | ./start-server.sh
  
  # Pre configure the server properties file
  sed -i 's/motd=.*/motd=NEEEEEEEEEEEEEEEEEEEEEE/g' server.properties
  sed -i 's/enable-command-block=false/enable-command-block=true/g' server.properties
  sed -i 's/white-list=false/white-list=true/g' server.properties
  sed -i 's/allow-flight=false/allow-flight=true/g' server.properties
  sed -i 's/enforce-whitelist=false/enforce-whitelist=true/g' server.properties
  sed -i 's/difficulty=.*/difficulty=2/g' server.properties

fi

chmod +x /minecraft/start-server.sh



# Sets the user minecraft the owner of every file
chown -R minecraft:sudo /minecraft

# Enables the minecraft service, although it will basically crash loop till the start-server.sh server can actually start a server
systemctl enable minecraft.service
systemctl start minecraft