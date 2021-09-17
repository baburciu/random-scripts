# /root/bogdanb/run_robot.sh:

#!/bin/bash

iterations_nr=200
cd /home/python_scripts/XX

for i in $(seq 0 $(( $iterations_nr - 1 )) ); do
    crash_nr=`ssh -i /root/bogdanb/Contrail2011_id_rsa -t 192.168.201.X ssh 192.168.Y.Z "ls -lt /var/crashes/ | wc -l"`
    # stripping out control characters which are mostly the character with ASCII value from 1 (octal 001) to 31 (octal 037), per https://www.shell-tips.com/bash/math-arithmetic-calculation/
    crash_nr=${crash_nr//[ $'\001'-$'\037']}
    echo -e "\t >> This is iteration $i"
    robot --pythonpath . --outputdir ./suites_OLN_RO/MAC-IP_Learn/debug_output -l DEBUG_$i --variable pop_id:G4R2_2011  --variable suite_cfg:./suites_OLN_RO/MAC-IP_Learn/conf/cpt_d__dpdk_mix__ipmac_d__flow_y__fwd_l2_l3.yaml ./suites_OLN_RO/MAC-IP_Learn/0001_MAC-IP_Learn.robot
    if [[ $crash_nr -eq 7 ]]; then
        break
    fi
    sleep 3m
done
