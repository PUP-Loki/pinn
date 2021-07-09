#!/bin/bash
touch menu.dat
echo "Unset" | tee menu.dat
menu_option_one() {
  curl -sL https://gitea.lokisys.icu/PUP-Loki/proxmox-scripts/raw/branch/main/lxc/nginx-proxy-manager/create.sh | bash -s
}

menu_option_two() {
 pct stop $REFID ; pct destroy $REFID ; echo "Unset" | tee menu.dat
}

press_enter() {
  echo ""
  echo -n "	Press Enter to continue "
  read
}

incorrect_selection() {
  echo "Incorrect selection! Try again."
}

until [ "$selection" = "0" ]; do
REFID=$(cat menu.dat)
  echo ""
  echo "    	1  -  Build"
  echo "    	2  -  Destroy"
  echo "    	0  -  Exit"
  echo ""
  echo -n "  Enter selection: "
  read selection
  echo ""
  case $selection in
    1 ) clear ; menu_option_one ; press_enter ;;
    2 ) clear ; menu_option_two ; press_enter ;;
    0 ) clear ; exit ;;
    * ) clear ; incorrect_selection ; press_enter ;;
  esac
done
