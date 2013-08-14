require 'spec_helper'

module VCloudCloud
  module Steps

    describe Instantiate do

      let(:template_id) {"tid"}
      let(:vapp_name) {"vapp_name"}
      let(:vapp_description) {"This is a vapp"}

      let(:disk) do
        disk = double("disk").as_null_object
        disk
      end

      let(:vm) do
        vm = double("vm").as_null_object
        vm
      end

      let(:catalog_item) do
        item = double("catalog item")
        item.stub(:entity) {template}
        item
      end

      let(:template) do
        template = double("vapp template")
        template.stub(:[]) {"value"}
        template.stub(:vms) {[vm]}
        template
      end

      let(:vapp) do
        vapp = double("vapp")
        vapp
      end

      let(:instantiate_vapp_template_link_value) {"http://vdc/instantiate/vapp/template"}
      let(:client) do
        client = double("vcloud client")
        client.stub(:logger) { Bosh::Clouds::Config.logger }
        client.stub(:resolve_entity) do |arg|
          catalog_item if arg == template_id
        end
        client.stub(:resolve_link) do |arg|
          arg
        end
        client.stub(:invoke) do |method,link,params|
          vapp if method == :post && link == instantiate_vapp_template_link_value
        end
        client.stub_chain(:vdc, :instantiate_vapp_template_link) {instantiate_vapp_template_link_value}
        client.stub(:wait_entity) do |arg|
          arg
        end
        client
      end

      describe ".perform" do
        it "creates the vapp" do
          # setup test data
          disk_locality = [nil, disk, disk]
          state = {}

          # configure mock expectations
          client.should_receive(:resolve_entity).once.ordered.with(template_id)
          catalog_item.should_receive(:entity).once.ordered
          client.should_receive(:resolve_link).once.ordered.with(template)
          template.should_receive(:vms).twice.ordered
          client.should_receive(:vdc).once.ordered
          client.should_receive(:invoke).once.ordered.with(:post, instantiate_vapp_template_link_value, kind_of(Hash))
          client.should_receive(:wait_entity).once.ordered.with(vapp)

          # run the test
          step = described_class.new state, client
          step.perform template_id, vapp_name, vapp_description, disk_locality
          expect(state[:vapp]).to eql vapp
        end

        it "raises ObjectNotFoundException" do
          # setup test data
          tid = "test"
          disk_locality = []
          state = {}

          # config mock expectations
          client.should_receive(:resolve_entity).once.ordered.with(tid)

          # run the test
          step = described_class.new state, client
          expect{step.perform tid, vapp_name, vapp_description, disk_locality}.to raise_exception ObjectNotFoundError
          expect(state).to be {}
        end
      end
    end

  end
end
