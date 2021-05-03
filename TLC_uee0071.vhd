-- Code for Counter Box : maintains and outputs values of two counters {count_noped (counts upto 680 sec) and count_ped (counts upto 80 sec)} --
library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity counter_box is
    port ( clk, p_flag : in std_logic;  -- p_flag determines which counter to be incremented
		count_noped : out std_logic_vector(9 downto 0); -- counts upto 680 sec
		count_ped : out std_logic_vector(6 downto 0)); -- counts upto 80 sec
end counter_box;

architecture behavioral of counter_box is
	signal cnp : unsigned(9 downto 0) := "0000000000";
	signal cp : unsigned(6 downto 0) := "0000000";
begin
	process(clk, p_flag) is
	begin
		if(rising_edge(clk) and p_flag = '0') then
			cp <= "0000000";
			if(cnp = "1010100111") then
				cnp <= "0000000000";
			else cnp <= cnp + 1;
			end if;
		elsif(rising_edge(clk) and p_flag = '1') then
			cnp <= cnp;
			if(cp = "1001111") then
				cp <= "0000000";
			else cp <= cp + 1;
			end if;
		end if;
		count_noped <= std_logic_vector(cnp);
		count_ped <= std_logic_vector(cp);
	end process;
end behavioral;

---------------------------------------------------------------------------------------
-- Code for p_flag selector : on rising edge of p_ctrl, p_flag is set to '1' for entire duration of pedestrian crossing i.e 1min + 20sec. 
-- Also handles subsequent button press by pedestrian during single pedestrian crossing cycle --
library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity p_flag_sel is
    port ( p_ctrl : in std_logic; -- when pedestrian pushes button, p_ctrl = '1' for the duration of button press, else p_ctrl = '0'
		cp : in std_logic_vector(6 downto 0); -- counter value corresponding to count_ped (cp) counter
		p_flag : out std_logic );
end p_flag_sel;

architecture behavioral of p_flag_sel is
begin
	process(p_ctrl, cp) is
	begin
		if(rising_edge(p_ctrl) and cp = "0000000") then
			p_flag <= '1';
		elsif(p_ctrl = '0' and cp = "0000000") then
			p_flag <= '0';
		end if;
	end process;
end behavioral;

---------------------------------------------------------------------------------------
-- Code for light selector when no pedestrian --
library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity light_sel_noped is
    port ( cnp : in std_logic_vector(9 downto 0); -- counter value corresponding to count_noped (cnp) counter
		H : out std_logic_vector(2 downto 0);
		S : out std_logic_vector(2 downto 0);
		P : out std_logic_vector(2 downto 0));
end light_sel_noped;

architecture behavioral of light_sel_noped is
begin
	process(cnp) is
	begin
		if(cnp = "0000000001") then -- @ 1 sec
			H <= "100";
			S <= "001";
			P <= "001";
		elsif(cnp = "1001011000" or cnp = "1010011110") then -- @ 600 sec or @ 670 sec
			H <= "010";
			S <= "010";
			P <= "001";
		elsif(cnp = "1001100010") then -- @ 610 sec
			H <= "001";
			S <= "100";
			P <= "001";
		end if;
	end process;
end behavioral;

---------------------------------------------------------------------------------------
-- code for light selector when pedestrian is crossing --
library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity light_sel_ped is
    port ( cp : in std_logic_vector(6 downto 0); -- counter value corresponding to count_ped (cp) counter
		H : out std_logic_vector(2 downto 0);
		S : out std_logic_vector(2 downto 0);
		P : out std_logic_vector(2 downto 0));
end light_sel_ped;

architecture behavioral of light_sel_ped is
begin
	process(cp) is
	begin
		if(cp = "0000001" or cp = "1000110") then --@ 1 sec or @ 70 sec
			H <= "010";
			S <= "010";
			P <= "010";
		elsif(cp = "0001010") then --@ 10 sec
			H <= "001";
			S <= "001";
			P <= "100";
		end if;
	end process;
end behavioral;

---------------------------------------------------------------------------------------
-- code for final light selection based on p_flag value --
library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity light_sel is
    port ( p_flag : in std_logic; 
		H1, H2 : in std_logic_vector(2 downto 0);
		S1, S2 : in std_logic_vector(2 downto 0);
		P1, P2 : in std_logic_vector(2 downto 0);
		H, S, P : out std_logic_vector(2 downto 0));
end light_sel;

architecture structure of light_sel is
	signal hh, ss, pp : std_logic_vector(2 downto 0);
begin
	hh <= H1 when p_flag = '0' else
		 H2 when p_flag = '1' else
		 hh;
	ss <= S1 when p_flag = '0' else
		 S2 when p_flag = '1' else
		 ss;
	pp <= P1 when p_flag = '0' else
		 P2 when p_flag = '1' else
		 pp;
	H <= hh;
	S <= ss;
	P <= pp;
end structure;

---------------------------------------------------------------------------------------
-- code for Traffic_lights_controller --
library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity Traffic_lights_controller is
    port ( p_ctrl : in std_logic; -- when pedestrian pushes button, p_ctrl = '1' for the duration of button press, else p_ctrl = '0'
		H, S, P : out std_logic_vector(2 downto 0)); -- Highway, Sideway and Pedestrian lights : "001" = red, "010" = yellow and "100" = green
end Traffic_lights_controller;

architecture structure of Traffic_lights_controller is
	component counter_box is
    port ( clk, p_flag : in std_logic;
		count_noped : out std_logic_vector(9 downto 0);
		count_ped : out std_logic_vector(6 downto 0));
	end component;
	component p_flag_sel is
    port ( p_ctrl : in std_logic; 
		cp : in std_logic_vector(6 downto 0);
		p_flag : out std_logic );
	end component;
	component light_sel_noped is
    port ( cnp : in std_logic_vector(9 downto 0);
		H : out std_logic_vector(2 downto 0);
		S : out std_logic_vector(2 downto 0);
		P : out std_logic_vector(2 downto 0));
	end component;
	component light_sel_ped is
    port ( cp : in std_logic_vector(6 downto 0);
		H : out std_logic_vector(2 downto 0);
		S : out std_logic_vector(2 downto 0);
		P : out std_logic_vector(2 downto 0));
	end component;
	component light_sel is
    port ( p_flag : in std_logic; 
		H1, H2 : in std_logic_vector(2 downto 0);
		S1, S2 : in std_logic_vector(2 downto 0);
		P1, P2 : in std_logic_vector(2 downto 0);
		H, S, P : out std_logic_vector(2 downto 0));
	end component;
	
	signal clk_1s, p_flag : std_logic;
	signal cnp : std_logic_vector(9 downto 0) := "0000000000";
	signal cp : std_logic_vector(6 downto 0) := "0000000";
	signal H1, H2, S1, S2, P1, P2 : std_logic_vector(2 downto 0);
	
begin
	
	proc_1s_clk: process
	begin
		clk_1s <= '1';
		wait for 500 ms;
		clk_1s <= '0';
		wait for 500 ms;
	end process;
	
	gen_counter_box: counter_box 
	port map(clk => clk_1s, p_flag => p_flag, count_noped => cnp, count_ped => cp);
	
	gen_pflag_sel: p_flag_sel
	port map(p_ctrl => p_ctrl, cp => cp, p_flag => p_flag);
	
	gen_light_sel_noped: light_sel_noped
	port map(cnp => cnp, H => H1, S => S1, P => P1);
	
	gen_light_sel_ped: light_sel_ped
	port map(cp => cp, H => H2, S => S2, P => P2);
	
	gen_light_sel: light_sel
	port map(p_flag => p_flag, H1 => H1, H2 => H2, S1 => S1, S2 => S2, P1 => P1, P2 => P2, H => H, S => S, P => P);
	
end structure;