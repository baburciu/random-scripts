# prereq: 
# - VERSION=v4.25.3 BINARY=yq_linux_amd64 ; wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY} -O /usr/bin/yq && chmod +x /usr/bin/yq
# - git version 2.25.1
# - git config --global alias.push-from-git '!f() { git push -o merge_request.target=master -o merge_request.create -o merge_request.description="Removed consul server references from consul-template." -o merge_request.unassign="baburciu" -o merge_request.title="Draft: $(git show --pretty=format:%s -s HEAD)" $* 2>&1 | sed "s/git push --set-upstream/git push-from-git --set-upstream/"; }; f'

# how to run: bash delete_consul_mr_new.sh -d ./dir-w-helm-charts

#!/bin/bash

# configure script to exit as soon as any line in the bash script fails and show that line
set -e

# using flags for passing input to script
while getopts d: flag
do
    case "${flag}" in
        d) dir_path_iac=${OPTARG};;
    esac
done

cd $dir_path_iac
git config --global credential.helper store
git config --global credential.helper 'cache --timeout 3600'

for helm_chart_dir in `ls -lX . | grep -vE "some|dir" | awk '{print $9}'`; do 
    echo "=================" && echo -e "\t\t in $dir_path_iac/$helm_chart_dir:" 
    cd $helm_chart_dir; ls -lrX values.yaml 
    helm_chart_values_path=` ls -lrX values.y* | awk '{print $9}'`
    ok_to_change=false
    echo "-----------------------------------------------------------------------"; echo "";  
    # only create new branch and check for consul server line in values.yaml when the chart values contains it
    if grep -q "some-text-to-delete-from-yaml" $helm_chart_values_path; then
        new_branch="bb/remove-consul-section-${helm_chart_dir}"
        git checkout -b ${new_branch}
        sleep 1
        git config --global user.name "<>"
        git config --global user.email "<>" 
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_base_config.consul.address |key |line" values.yaml` 
        # beside line number >0, need to also check that line contains "consul", since yq does not account header comment lines in numbering lines
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_base_config.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi        
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config.consul.address |key |line" values.yaml` 
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config_keyring.consul.address |key |line" values.yaml` 
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config_keyring.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config_saml.consul.address |key |line" values.yaml` 
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config_saml.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config_tls.consul.address |key |line" values.yaml` 
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_config_tls.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_exporter_config.consul.address |key |line" values.yaml` 
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_exporter_config.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi
        line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_openstack_cloud_config.consul.address |key |line" values.yaml` 
        if [[ $line_nr -gt 0 ]]; then
            if [[ `sed -n ${line_nr}p $helm_chart_values_path` == *"consul"* ]]; then
                ok_to_change=true
                sed -i "${line_nr}d" $helm_chart_values_path
                line_nr=`yq eval ".conf.some_dict_key_in_yaml_to_delete_openstack_cloud_config.consul |key |line" values.yaml` 
                sed -i "${line_nr}d" $helm_chart_values_path
            fi
        fi
        git diff --unified=0 $helm_chart_values_path
        git add $helm_chart_values_path
        git checkout -- Chart.yaml
        if [ "$ok_to_change" = true ] ; then
            git commit -m "[OIAASVL-6265] Removed consul key from values.yaml .conf.consul_template"
            git status
            git push-oiaas -u origin ${new_branch} | grep merge_requests >> /home/ubuntu/delete_consul_mrs.txt
        else
            echo -e "\t branch ${new_branch} has no changes because  $helm_chart_dir/$helm_chart_values_path has first lines with comments and yq skips them"    
            echo -e "\t branch ${new_branch} has no changes because  $helm_chart_dir/$helm_chart_values_path has first lines with comments and yq skips them" >> /home/ubuntu/delete_consul_manual_mrs_need.txt
        fi
        git checkout master
    else
        echo "Consul server not used in $helm_chart_dir"
    fi
    cd .. ; echo "" 
    sleep 1
done
