--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnL    :   in std_logic; -- clock reset
        btnC    :   in std_logic; -- fsm cycle
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
     signal w_clk_in : std_logic;
     signal w_reset_in : std_logic;
     signal w_button_out : std_logic;
     signal w_o_cycle : STD_LOGIC_VECTOR (3 downto 0);
     signal w_reg_1_out : STD_LOGIC_VECTOR (7 downto 0);
     signal w_reg_2_out : STD_LOGIC_VECTOR (7 downto 0);
     signal w_alu_out : STD_LOGIC_VECTOR (7 downto 0);
     signal w_i_bin : STD_LOGIC_VECTOR (7 downto 0);
     signal w_sign_1 : STD_LOGIC;
     signal w_sign_2 : std_logic_vector(3 downto 0);
     signal w_ones : std_logic_vector(3 downto 0);
     signal w_tens : std_logic_vector(3 downto 0);
     signal w_huns : std_logic_vector(3 downto 0);
     signal w_tdm_o : std_logic_vector(3 downto 0);
      signal w_final_o : std_logic_vector(6 downto 0);
     signal w_clk_out: std_logic;
     signal w_clk_fast_out : std_logic;
     signal w_an : std_logic_vector(3 downto 0);
     
  
	-- declare components and signals
	component button_debounce is
        Port(	clk: in  STD_LOGIC;
			reset : in  STD_LOGIC;
			button: in STD_LOGIC;
			action: out STD_LOGIC);
    end component button_debounce;
    
    component controller_fsm is
        Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
    end component controller_fsm;
    
    component clock_divider is
	generic ( constant k_DIV : natural := 2	);
	port ( 	i_clk    : in std_logic;		   -- basys3 clk
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
	end component clock_divider;
	
	component ALU is
	Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
           end component ALU;
           
     component twos_comp is
     port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
    end component twos_comp;
    
    component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
    
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
  
begin
	-- PORT MAPS ----------------------------------------
    button: button_debounce port map (
           clk => clk,
           reset => w_reset_in,
           button => btnC,
           action => w_button_out
        );
    controller: controller_fsm port map (
           i_adv => w_button_out,
           i_reset => w_reset_in,
           o_cycle => w_o_cycle
        );
    
    ALU0: ALU port map (
           i_A => w_reg_1_out,
           i_B => w_reg_2_out,
           i_op => sw(2 downto 0),
           o_result => w_alu_out,
           o_flags => led(15 downto 12)
           
        );
   twocom : twos_comp port map
   (
        i_bin => w_i_bin,
        o_sign => w_sign_1,
        o_hund => w_huns,
        o_tens => w_tens,
        o_ones => w_ones
   );
   
   clkdiv_inst : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 200000 ) -- 16 ms
        port map (						  
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => w_clk_out
        );    
        
    clkdiv_inst_faster : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 125 ) -- 100000 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset => btnL,
            o_clk   => w_clk_fast_out
        );    
   
   tdm: TDM4 port map (
            i_clk		=> w_clk_out,
           i_reset		=> w_reset_in,
           i_D3 		=> w_sign_2,
		   i_D2 		=> w_huns,
		   i_D1 		=> w_tens,
		   i_D0 		=> w_ones,
		   o_data		=> w_tdm_o,
		   o_sel		=> w_an
        );
        
   sevenseg: sevenseg_decoder port map (
           i_Hex => w_tdm_o,
           o_seg_n => w_final_o
        );
        
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	process (clk)
begin
  if rising_edge(clk) then
    if btnU = '1' then
      w_reg_1_out <= (others => '0');
    elsif w_o_cycle = "0001" then
      w_reg_1_out <= sw;
    end if;
  end if;
end process;
  
  process (clk)
begin
  if rising_edge(clk) then
    if btnU = '1' then
      w_reg_2_out <= (others => '0');
    elsif w_o_cycle = "0010" then
      w_reg_2_out <= sw;
    end if;
  end if;
end process;
	
	w_reset_in <= btnU;
	w_sign_2 <= "1111" when w_sign_1 = '1' else
	       "0000";
	
	led(3 downto 0) <= w_o_cycle;
	w_i_bin <= w_reg_1_out when (w_o_cycle = "0010") else
           w_reg_2_out when (w_o_cycle = "0100") else
           w_alu_out   when (w_o_cycle = "1000") else
           (others => '0');
    process(clk)
begin
    if rising_edge(clk) then
        if w_o_cycle = "0001" then
            an <= "1111";
        else
            an <= w_an;
        end if;
        if (w_an = "0111" and w_sign_1 = '1') then
            seg <= "0111111"; -- (-)
        else
            seg <= w_final_o;
        end if;
    end if;
end process;
   
    
	
end top_basys3_arch;
