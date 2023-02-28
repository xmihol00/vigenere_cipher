library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- rozhrani Vigenerovy sifry
entity vigenere is
   port(
         CLK : in std_logic;
         RST : in std_logic;
         DATA : in std_logic_vector(7 downto 0);
         KEY : in std_logic_vector(7 downto 0);

         CODE : out std_logic_vector(7 downto 0)
    );
end vigenere;

architecture behavioral of vigenere is

    signal offset: std_logic_vector (7 downto 0); -- hodnota posunu na zaklade pismena v test bench
    signal plus_correction: std_logic_vector (7 downto 0); -- opravena hodnota posunu pro pricitani
    signal minus_correction: std_logic_vector (7 downto 0); -- opravena hodnota posunu pro odecitani

    type mealy_fsm_state is (ADD, SUB);
    signal mealy_current_state: mealy_fsm_state; -- ve stavu ADD dochazi k pricitani s opravou
    signal mealy_next_state: mealy_fsm_state;	-- ve stavu SUB dochazi k odecitani s opravou

    signal mealy_fsm_out: std_logic_vector (1 downto 0); -- 2 bit vystup mealyho automatu a pote vstup do multiplexoru jako selector

begin
    
    offset <= KEY - 64; -- 64 + 1 == 'A' v ASCII (off by 1)

    plus_correction_process: process (DATA, offset) is
    begin
	if (DATA + offset > 90) then -- 90 == 'Z' v ASCII
		plus_correction <= DATA + offset - 26; -- oprava preteceni, 26 == pocet znaku v anglicke abecede
	else
		plus_correction <= DATA + offset; -- oprava neni potreba
	end if;
    end process plus_correction_process;

    minus_correction_process: process (DATA, offset) is
    begin
	    if (DATA - offset < 65) then
		    minus_correction <= DATA - offset + 26; -- oprava podteceni, 26 == pocet znaku v anglicke abecede
	    else
		    minus_correction <= DATA - offset; --oprava neni potreba
	    end if;
    end process minus_correction_process;


    mealy_register_logic: process (RST, CLK) is -- zmena aktualniho stavu mealyho automatu
    begin
	    if (RST = '1') then
		    mealy_current_state <= ADD;
	    elsif rising_edge(CLK) then
		    mealy_current_state <= mealy_next_state;
	    end if;
    end process mealy_register_logic;

    mealy_nstate_out_logic: process (mealy_current_state, DATA, RST) is -- urceni nasledujiciho stavu mealyho automatu
    begin
	    if (mealy_current_state = ADD) then
		    mealy_next_state <= SUB;
		    mealy_fsm_out <= "00";
		    if ((DATA >= 48 and DATA <= 57) or RST = '1') then -- 48 == '0' a 57 == '9' v ASCII
			    mealy_fsm_out <= "11";
		    end if;
	    else
		    mealy_next_state <= ADD;
		    mealy_fsm_out <= "01";
		    if ((DATA >= 48 and DATA <= 57) or RST = '1') then
			    mealy_fsm_out <= "10";
		    end if;
	    end if;
    end process mealy_nstate_out_logic;

    --multiplexor 4 na 1, vstupy "00" a "01" vybiraji mezi pricitanim a odcitanim, vstupy "10" a "11" zpusobuji na vystupu znak '#'
    CODE <= plus_correction  when mealy_fsm_out = "00" else
	    minus_correction when mealy_fsm_out = "01" else
	    "00100011";

end behavioral;
