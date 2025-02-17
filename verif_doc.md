# Verification environment
Środowisko bazuje na cocotb i uruchamiane jest za pomocą oprogramowania Makefile. Obsługuje dwa targety oraz trzy zmienne.
***
### Targety:
 - **clean_dirs** - Kasuje foldery sim_dir oraz \_\_pycache\_\_ \
 - **all** - Uruchamia środowisko \

Oba targety muszą zostać wykonane równolegle
### Zmienne:
 - **ORDER=val**, val=<1,2> - Pozwala na wybranie rzędu modulatora SDM dla jakiego zostanie przygotowane środowisko (design i weryfikacja)
 - **ADC_TYPE=val**, val=<1,2> - Pozwala na wybranie rodzaju filtra użytego do demodulacji \
 1 - filtr uśredniający \
 2 - filtr grzebieniowy
 - **UVM=val**, val=<0,1> - Pozwala na wybranie rodzaju testbencha \
 0 - Testbench warstwowy na bazie cocotb \
 1 - Testbench z wykorzystaniem pyUVM

### Test:
- Oba testbenche uruchamiają tylko jeden test "functionality", którego wynik w postaci tekstowej widoczny jest w terminalu, oraz w postaci graficznej za pomocą wykresów porównujących ze sobą wynik otrzymany z modelu oraz z naszej implementacji sprzętowej.
- Wynik testu ustalany jest na podstawie porównania wartości otrzymanych z operacji splotu wartości funkcji uzyskanej z oknem jedynek o szerokości 256 oraz równych wagach, identyczna operacja wykonana jest dla wartości uzyskanych z modelu. Jeżeli średnia ważona z wartości bezwzględnej z różnicy tych funkcji przekroczy 0.1 to wynik testu jest negatywny (Fail)

### Przykłady użycia:
~~~sh
make clean_dirs all UVM=1 ORDER=1 ADC_TYPE=1
~~~

~~~sh
make clean_dirs all UVM=0 ORDER=2 ADC_TYPE=1
~~~