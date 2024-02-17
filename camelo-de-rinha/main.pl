#!/usr/bin/env perl

# 
# XGH aplicado
#

use Mojolicious::Lite -signatures;
use Mojo::Pg;

helper pg => sub { state $pg = Mojo::Pg->new('postgresql://postgres:123@localhost/rinha') };

my $em_teste = 1;
post '/clientes/:id_cliente/transacoes' => sub ($self) {
	my $payload = $self->req->json;
	return $self->render(status => 422, text => "Sem desc?") unless $payload->{descricao};
	my $desln = length($payload->{descricao});
	return $self->render(status => 422, text => "Descrição está zoado") if $desln < 1 or $desln > 10;
	return $self->render(status => 422, text => "Esse tipo ta estranho ein") if $payload->{tipo} ne "c" and $payload->{tipo} ne "d";
	return $self->render(status => 422, text => "Apenas inteiros meu consagrado") unless $payload->{valor} =~ m/^-?\d+$/;
	my $id_cliente = $self->param('id_cliente');
	my $db = $self->pg->db;
	my $op = $payload->{tipo} eq "c" ? "+" : "-";	
	# sql injection, eu sei	
	my $qupdt = $db->query(qq{ UPDATE cliente SET saldo = saldo $op ? where id_cliente = ? and (saldo$op?) < limite and (saldo$op?) > (limite*-1) returning saldo, limite; }, $payload->{valor}, $id_cliente, $payload->{valor}, $payload->{valor})->hash;
	return $self->render(status=>422, text=>"") unless $qupdt;
	$db->query(qq{ INSERT INTO transacao (id_cliente, valor, tipo, descricao) VALUES (?, ?, ?, ?) }, $id_cliente, $payload->{valor}, $payload->{tipo}, $payload->{descricao});
	$self->render(json => { limite => $qupdt->{limite}, saldo => $qupdt->{saldo} }, status => 200);	
};

get '/clientes/:id_cliente/extrato' => sub ($self) {
	my $id_cliente = $self->param('id_cliente');
    my $qsaldo = $self->pg->db->query(q{ SELECT saldo as total, limite, NOW() as data_extrato FROM cliente WHERE id_cliente = ? }, $id_cliente);		
	return $self->render(status => 404, text => "Puts, ve no ipiranga se eles conhecem esse cara ai") if $qsaldo->rows eq 0;
	my $qtransacap = $self->pg->db->query(q{ SELECT t.valor, t.tipo, t.descricao, t.realizada_em FROM transacao t WHERE t.id_cliente = ? order by realizada_em desc limit 10; }, $id_cliente);
	$self->render(json => { saldo => $qsaldo->hash, ultimas_transacoes => $qtransacap->hashes->to_array }, status => 200);
};

my $PORTA = $ENV{'PERL_HTTP_PORT'};
app->mode('production');
app->config(
    hypnotoad => {
        listen => [ "http://*:$PORTA/" ],
    },
);
app->start;
