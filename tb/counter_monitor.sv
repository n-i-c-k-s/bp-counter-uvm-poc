// Monitor: observes the count output and writes transactions to analysis port
class counter_monitor extends uvm_monitor;
    `uvm_component_utils(counter_monitor)

    virtual counter_if vif;
    uvm_analysis_port #(counter_seq_item) ap;

    // Covergroup: covers count value ranges
    covergroup count_cg;
        cp_count: coverpoint vif.monitor_cb.count {
            bins zero        = {8'h00};
            bins low         = {[8'h01 : 8'h3F]};
            bins mid         = {[8'h40 : 8'hBF]};
            bins high        = {[8'hC0 : 8'hFE]};
            bins max_val     = {8'hFF};
        }
        cp_enable: coverpoint vif.monitor_cb.enable {
            bins enabled  = {1'b1};
            bins disabled = {1'b0};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        count_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual counter_if)::get(this, "", "vif", vif))
            `uvm_fatal("CFG", "counter_monitor: cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        counter_seq_item item;
        forever begin
            @(vif.monitor_cb);
            count_cg.sample();
            item = counter_seq_item::type_id::create("mon_item");
            item.enable     = vif.monitor_cb.enable;
            item.num_cycles = 1;
            ap.write(item);
            `uvm_info("MON", $sformatf("Observed count=0x%02h enable=%0b",
                      vif.monitor_cb.count, vif.monitor_cb.enable), UVM_HIGH)
        end
    endtask
endclass
