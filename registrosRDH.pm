=encoding utf8

=pod
 
=head1 NOMBRE

registrosRDH

=head1 DESCRIPCIÓN

Sistema de registro para la red distribuida de Honeypots.
El sistema hace uso de una interfaz web para el registro de honeypots.

El usuario accede a la página web dónde se le solicitan los siguientes datos:

Nombre de la institución
Número de honeypotsa registrar
Tipo de Honeypot (pueden ser uno o más por cada solicitud)
Dirección IP del Honeypot


Como salida se mostrarán en el navegador web los resultados del registro realizado
asi como también se generará un archivo rdh.csv con el siguiente formato:

Fecha y hora de la solicitud,Nombre de la Institución,Tipo de Honeypot,IP,ID,Contraseña

=head1 REQUERIMIENTOS


Instalacion de módulos:

HTML::Template,
CGI::Application,
CGI::Application::Plugin::Forward,
UUID::Generator::PurePerl,
Data::UUID,
String::MkPasswd 

=head1 EJECUCION


Ingresar desde el navegador a la dirección donde se encuentre el archivo de perl:
Ejemplo:

http://localhost/perl/rdhAPP.pl

en el caso en que se encuentre en un servidor local

=cut



#!/usr/bin/perl
use strict;
package registrosRDH;

use HTML::Template;
use parent 'CGI::Application';
use CGI::Application::Plugin::Forward;
use UUID::Generator::PurePerl;

our $institucion;
our $file  = 'rdh.csv';		
our @datos;
use Data::UUID;
use String::MkPasswd qw(mkpasswd);

sub setup
{ #CGI application indica que debes tener un setup y se indicaran aqui los modos de ejecución 
    my $self = shift; #se pasa la referencia del propio objeto
    $self->run_modes
    ( #como se va llamar el modo de ejecucuón y que subrutina va a ejecutar
        'view' => 'inicio',
        'ingresa' => 'ingresa',     
        'resultado' => 'resultado',
    ); 
    $self->start_mode('view'); #en que modo de ejecución va iniciar la aplicación 
    $self->mode_param('selector'); #con selectorCGI aplication va identificar cual es el value que va servir para cambiar modo de ejecucion
}


=head1 SUBRUTINAS

=over 

=item -B<inicio>

Subrutina inicio:
En esta parte es donde presentamos el formulario para ingresar la institución y el núemro de honeypots a registrar

=cut

sub inicio
{
	my $template = HTML::Template->new(filename => './inicio.tmpl');
	return $template->output();
}

=item -B<ingresa>

Subrutina ingresa:
En esta parte es donde presentamos el formulario para ingresar los N datos, donde N
es el numero de honeypots que el usuario puso que ingresaria.

=cut

sub ingresa
{
	my $self = shift;
	my $q = $self->query();
	my $a=$q->param('institucion');
	my $b=$q->param('numero');
	my $template = HTML::Template->new(filename => './ingresa.tmpl');
	my @loop_data;
	for(my $i=1; $i<=$b;$i++)
	{
		push @loop_data,{	
							institucion => $a,
							number => $i,
							tipo => "tipo".$i,
							ip => "ip".$i
						}
	}
	$template->param(numero => \@loop_data);
	$template->param(total => $b);
	$template->param(institucion => $a);

	return $template->output();
}

=item -B<resultado>

La subrutina resultado obtiene todos los datos recabados y si todos son validos, los presenta en pantalla 
y los guarda en un archivo .csv

=cut

sub resultado{
	#Obtenemos el timestamp
	my $self = shift;
	my $q = $self->query();
	my $salida;
	my @loop_data;
	#Obtenemos los datos necesarios
	my $total = $q->param('total');
	my $institucion = $q->param('institucion');
	#Iteramos para cada Honeypot, en este caso guardaremos en una variable los datos concatenados
	#Cada ciclo pasaremos esa variable a un arreglo y al iniciar el nuevo ciclo se vuelve a repetir el proceso
	for(my $i=1; $i<=$total;$i++)
	{	
		my $tipo = $q->param('tipo'.$i);
		my $ip = $q->param('ip'.$i);
		my $id = &getID;
		my $timestamp = &getTimeStamp;
		my $passwd = &getPasswd;
		$salida = "$timestamp, $institucion , $tipo , $ip , $id , $passwd\n";
		push(@datos,$salida);
		push @loop_data,{	
							linea => $salida,
						}
	}

	my $template = HTML::Template->new(filename => './resultados.tmpl');
	#Variable de prueba, solo para ver que esta imprimiendo algo
	$template->param(resultados => \@loop_data);

	#EN ESTA PARTE IRIA LA IMPRESION HACIA LA PANTALLA
	open (RDH, ">>", $file) or die "No se pudo crear el archivo '$file' $!";
	print RDH @datos;
	return $template->output();
}

=item -B<getID>

La subrutina getID obtiene un UUID unico.
UUID::Generator::PurePerl UUID (Universally Unique IDentifier; descrito en el RFC4122)
Este generador nos ayudara a obtener un UUID version 4 de 128-bits, el cual es construido de numeros 
aleatorios

=cut

sub getID
{
	my $ug = UUID::Generator::PurePerl->new();
	my $uuid1 = $ug->generate_v4();
	return $uuid1->as_string();
}

=item -B<getTimeStamp>

La subrutina getTimeStamp generará el timestamp del momento en el que se llevó a cabo el registro de los 
honepots. El formato utilizado está basado en el estandar ISO

=cut

sub getTimeStamp {

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
    my $timestamp = sprintf ( "%04d-%02d-%02dT%02d:%02d:%02d+00:00",$year+1900,$mon+1,$mday,$hour,$min,$sec);
    return $timestamp;
}

=item -B<mkpasswd>

La subrutina mkpasswd generará claves aún más complejas, dichas claves cumplirán con las siguientes condiciones.
-length: La longitud total de la contraseña, 16 en este caso.
-minnum: El número mínimo de digitos. 5 en este caso.
-minlower: El número mínimo de caracteres en minúsculas, en este caso 5.
-minupper: El número mínimo de caracterés en mayúsculas, en este caso 3.
-minspecial: El número mínimo de caracteres no alfanuméricos, en este caso será de 3.
-distribute: Los caracteres de la contraseña serán distribuidos entre el lado izquierdo y derecho del teclado, esto hace más díficil que un fisgón vea la contraseña que uno está escribiendo. El valor predeterminado es falso, en este caso el valor es verdadero.
=back
=cut


sub getPasswd
{
    chomp;
    return $_, " ", mkpasswd(
	    -length => 16,
	    -minnum => 5,
	    -minlower => 5,
	    -minupper => 3,
	    -minspecial => 3,
	    -distribute => 1
    );
}

=head1 AUTORES

=over 

=item -Fernando Parra

=item -Cristian Monroy

=item -Jonathan Soto

=item -Yeudiel Hernández

=item -Ivan Hernández

=back

=cut

1
