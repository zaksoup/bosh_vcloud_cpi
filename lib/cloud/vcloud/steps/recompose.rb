module VCloudCloud
  module Steps
    # Recompose a vApp to add or remove VMs.
    # Ref: http://pubs.vmware.com/vcd-51/index.jsp#operations/POST-RecomposeVApp.html

    class Recompose < Step
      def perform(name, container_vapp, vm = nil, &block)
        params = VCloudSdk::Xml::WrapperFactory.create_instance 'RecomposeVAppParams'
        params.name = name
        params.all_eulas_accepted = true
        params.add_source_item vm.href if vm

        # HACK: Workaround. recomposeLink is not available when vapp is running (so force construct the link)
        recompose_vapp_link = container_vapp.recompose_vapp_link true
        state[:recompose_vapp_name] = name
        client.invoke_and_wait :post, recompose_vapp_link, :payload => params
      end

      def rollback
        # The recompose method is only used in create_vm step.
        # The rollback logic here is to delete the new-created VM.
        vm = state[:vm]
        vapp_name = state[:recompose_vapp_name]
        if !vm.nil? && !vapp_name.nil?
          @logger.debug "Requesting VM: #{vm.name}"

          begin
            client.flush_cache
            vapp = client.vapp_by_name vapp_name
            target_vm = vapp.vms.find { |v| v.name == vm.name }
            link = target_vm.remove_link true
            client.invoke_and_wait :delete, link if link
          rescue => ex
            @logger.debug(ex) if @logger
          end

          # remove the item from state
          state.delete :vm
          state.delete :recompose_vapp_name
        end
      end
    end
  end
end
