// Environment: instantiates and connects the agent
class counter_env extends uvm_env;
    `uvm_component_utils(counter_env)

    counter_agent agt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = counter_agent::type_id::create("agt", this);
    endfunction
endclass
