# Testplan Sigma-Delta modulator/demodulator

### Ogólny zarys
Projekt posłuży weryfikacji bloczku Sigma-Delta modulator/demodulator. Sprawdzenie będzie polegało na porównaniu właściwości bloku w symulacji i porównaniu ze specyfikacją dostarczoną wraz z opisem

### DUT
Blok składa się z dwóch części - modulator i demodulator. Oba mają niezależne zestawy wejść i wyjść. 

#### Modulator:
| Parametr | Jednostka | Komentarz |
| ----- | -------- | ----------- |
| clk | 44.1KHz | Zegar taktujący dla  modulatora. |
| audio_in | 16 bit  | Wejście danych audio dla modulatora. |
| valid_in | 1 bit | Sygnał walidacyjny danych 
wejściowych audio. |
| sdm_out  | 1 bit | Wyjście przetworzonych 
danych SDM z modulatora. |
| valid_out_dac | 1 bit | Sygnał walidacyjny danych wyjściowych SDM.|

#### Demodulator:
| Parametr | Jednostka | Komentarz |
| ----- | -------- | ----------- |
| clk | 2,8224 MHz | Zegar taktujący dla  demodulatora.  |
| sdm_in | 16 bit  | Wejście danych SDM dla  demodulatora. |
| rst_n | 1 bit | Sygnał resetujący cały układ |
| valid_in_adc  | 1 bit | Sygnał walidacyjny danych wejściowych SDM. |
| audio_out | 16 bit | Wyjście przetworzonych 
danych audio z demodulatora. |
| valid_out_adc | 1 bit | Sygnał walidacyjny danych wyjściowych audio. |

### Cel testowania
* Sprawdzenie funkcjnowania bloczków przez spawdzenie czy na wyjściu pojawiają się dane po podaniu danych i sygnału valid na wejście
* Sprawdzenie poprawności i błędu modulatora i demodulatora Sigma-Delta
* Sprawdzenie reakcji na dane niepoprawne

### Metodologia testów
Środowisko: Cocotb, komponenty z modułu cocotb-bus, pyuvm, modele pythonowe
Narzędzia: Icarus Verilog
Typy weryfikacji:
 - Testy bezpośrednie
 - Porównanie z modelem
 - Asercje
 - TBD: Coverage; Randomizacja

### Funkcjonalność i scenariusze testowe
* Działanie bloczków
    - Sprawdzenie czy po podaniu odpowiednich danych na wejście, na wyjściu pojawią się odpowiedznie dane (Scenariusz dla modulatora i demodulatora)
    - Sprawdzenie czy bloczki mogą działać równolegle przez podanie danych na wejście obu kierunków na raz

*  Porównanie z modelem
    - Sprawdzenie czy po podaniu identycznych danych na wejście modulatora i modelu, na wyjściu pojawią się takie same wartości
    - Sprawdzenie czy po podaniu identycznych danych na wejście demodulatora i modelu, na wyjściu pojawią się takie same wartości
    - Spawdzenie różnic między wartościami z DUTa i modelu
* TBD: Error testy i performance testy
* TBD: Testy regresyjne

### Metryki
* Poprawność designu względem modelu w procentach
* TBD: Coverage

### Debugowanie
* Analiza przebiegów czasowych
* Analiza zrzutów wartości z symulacji 
* Analiza wartości porównywanych między systemem

### Raportowanie
* Wyniki w postaci procentowej różnicy między modelem a wynikiem z designu
* Wyniki testów pass/fail
* TBD: Testy regresyjne 