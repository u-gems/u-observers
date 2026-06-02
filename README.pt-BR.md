<p align="center">
  <h1 align="center">👀 μ-observers</h1>
  <p align="center"><i>Implementação simples e poderosa do padrão observer.</i></p>
</p>

<p align="center">
  <a href="https://rubygems.org/gems/u-observers">
    <img alt="Gem" src="https://img.shields.io/gem/v/u-observers.svg?style=flat-square">
  </a>
  <a href="https://github.com/u-gems/u-observers/actions/workflows/ci.yml">
    <img alt="Build Status" src="https://github.com/u-gems/u-observers/actions/workflows/ci.yml/badge.svg">
  </a>
  <br/>
  <a href="https://qlty.sh/gh/u-gems/projects/u-observers"><img src="https://qlty.sh/gh/u-gems/projects/u-observers/maintainability.svg" alt="Maintainability" /></a>
  <a href="https://qlty.sh/gh/u-gems/projects/u-observers"><img src="https://qlty.sh/gh/u-gems/projects/u-observers/coverage.svg" alt="Code Coverage" /></a>
  <br/>
  <img src="https://img.shields.io/badge/Ruby%20%3E%3D%202.7%2C%20%3C%3D%20Head-ruby.svg?colorA=444&colorB=333" alt="Ruby">
  <img src="https://img.shields.io/badge/Rails%20%3E%3D%206.0%2C%20%3C%3D%20Edge-rails.svg?colorA=444&colorB=333" alt="Rails">
</p>

> [!IMPORTANT]
> **Nenhuma mudança que quebre a API — nunca.** `u-observers` é uma gem sem dependências da qual muitos projetos dependem (direta ou transitivamente). Seu papel é permanecer uma base estável e retrocompatível — toda mudança mantém o código existente funcionando.
>
> Saltos de versão major sinalizam apenas que uma versão de Ruby ou Rails foi removida da matriz suportada — pela SemVer, uma mudança no piso de dependências. Seu código continua funcionando.

Esta gem implementa o padrão observer[[1]](https://en.wikipedia.org/wiki/Observer_pattern)[[2]](https://refactoring.guru/design-patterns/observer) (também conhecido como publicar/assinar). Ela fornece um mecanismo simples para um objeto informar um conjunto de objetos de terceiros interessados ​​quando seu estado muda.

A biblioteca padrão do Ruby [tem uma abstração](https://ruby-doc.org/stdlib-2.7.1/libdoc/observer/rdoc/Observable.html) que permite usar esse padrão, mas seu design pode entrar em conflito com outras bibliotecas convencionais, como [`ActiveModel`/`ActiveRecord`](https://api.rubyonrails.org/classes/ActiveModel/Dirty.html#method-i-changed), que também tem o método [`changed`](https://ruby-doc.org/stdlib-2.7.1/libdoc/observer/rdoc/Observable.html#method-i-changed). Nesse caso, o comportamento ficaria comprometido por conta dessa sobrescrita de métodos.

Por causa desse problema, decidi criar uma gem que encapsula o padrão sem alterar tanto a implementação do objeto. O `Micro::Observers` inclui apenas um método de instância na classe de destino (sua instância será o sujeito/objeto observado).

# Índice <!-- omit in toc -->

- [Instalação](#instalação)
- [Compatibilidade](#compatibilidade)
  - [Uso](#uso)
    - [Compartilhando um contexto com seus observadores](#compartilhando-um-contexto-com-seus-observadores)
    - [Compartilhando dados ao notificar os observadores](#compartilhando-dados-ao-notificar-os-observadores)
    - [O que é `Micro::Observers::Event`?](#o-que-é-microobserversevent)
    - [Usando um callable como um observador](#usando-um-callable-como-um-observador)
    - [Chamando os observadores](#chamando-os-observadores)
    - [Notificar observadores sem marcá-los como alterados](#notificar-observadores-sem-marcá-los-como-alterados)
    - [Definindo observers que executam apenas uma vez](#definindo-observers-que-executam-apenas-uma-vez)
      - [`observers.attach(*args, perform_once: true)`](#observersattachargs-perform_once-true)
      - [`observers.once(event:, call:, ...)`](#observersonceevent-call-)
    - [Definindo observers com blocos](#definindo-observers-com-blocos)
      - [`observers.on()`](#observerson)
      - [`observers.once()`](#observersonce)
      - [Substituindo um bloco por um `lambda`/`proc`](#substituindo-um-bloco-por-um-lambdaproc)
    - [Desanexando observers](#desanexando-observers)
    - [Integrações ActiveRecord e ActiveModel](#integrações-activerecord-e-activemodel)
      - [`.notify_observers_on()`](#notify_observers_on)
      - [Anexando observers no nível da classe (`.notify_observers!()`)](#anexando-observers-no-nível-da-classe-notify_observers)
      - [`.notify_observers()`](#notify_observers)
  - [Desenvolvimento](#desenvolvimento)
  - [Contribuindo](#contribuindo)
  - [License](#license)
  - [Código de conduta](#código-de-conduta)

# Instalação

Adicione esta linha ao Gemfile da sua aplicação e execute `bundle install`:

```ruby
gem 'u-observers'
```

# Compatibilidade

| u-observers | branch | ruby     | activerecord    |
| ----------- | ------ | -------- | --------------- |
| unreleased  | main   | >= 2.7.0 | >= 6.0, <= Edge |
| 2.3.0       | v2.x   | >= 2.2.0 | >= 3.2, < 6.1   |
| 1.0.0       | v1.x   | >= 2.2.0 | >= 3.2, < 6.1   |

Esta biblioteca é testada (CI matrix) contra:

| Ruby / Rails | 6.0 | 6.1 | 7.0 | 7.1 | 7.2 | 8.0 | 8.1 | Edge |
| ------------ | --- | --- | --- | --- | --- | --- | --- | ---- |
| 2.7          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.0          | ✅  | ✅  | ✅  | ✅  |     |     |     |      |
| 3.1          |     |     | ✅  | ✅  | ✅  |     |     |      |
| 3.2          |     |     | ✅  | ✅  | ✅  | ✅  |     |      |
| 3.3          |     |     | ✅  | ✅  | ✅  | ✅  | ✅  | ✅   |
| 3.4          |     |     |     |     | ✅  | ✅  | ✅  | ✅   |
| 4.x          |     |     |     |     |     |     | ✅  | ✅   |
| Head         |     |     |     |     |     |     | ✅  | ✅   |

> **Nota**: O ActiveRecord não é uma dependência, mas você pode adicionar um módulo para habilitar alguns métodos estáticos que foram projetados para serem usados ​​com seus [callbacks](https://guides.rubyonrails.org/active_record_callbacks.html).

[⬆️ Voltar para o índice](#índice-)

## Uso

Qualquer classe com o `Micro::Observers` incluído pode notificar eventos para observadores anexados.

```ruby
require 'securerandom'

class Order
  include Micro::Observers

  attr_reader :code

  def initialize
    @code, @status = SecureRandom.alphanumeric, :draft
  end

  def canceled?
    @status == :canceled
  end

  def cancel!
    return self if canceled?

    @status = :canceled

    observers.subject_changed!
    observers.notify(:canceled) and return self
  end
end

module OrderEvents
  def self.canceled(order)
    puts "The order #(#{order.code}) has been canceled."
  end
end

order = Order.new
#<Order:0x00007fb5dd8fce70 @code="X0o9yf1GsdQFvLR4", @status=:draft>

order.observers.attach(OrderEvents)  # anexando vários observadores. Exemplo: observers.attach(A, B, C)
# <#Micro::Observers::Set @subject=#<Order:0x00007fb5dd8fce70> @subject_changed=false @subscribers=[OrderEvents]>

order.canceled?
# false

order.cancel!
# A mensagem abaixo será impressa pelo observador (OrderEvents):
# The order #(X0o9yf1GsdQFvLR4) has been canceled

order.canceled?
# true

order.observers.detach(OrderEvents)  # desanexando vários observadores. Exemplo: observers.detach(A, B, C)
# <#Micro::Observers::Set @subject=#<Order:0x00007fb5dd8fce70> @subject_changed=false @subscribers=[]>

order.canceled?
# true

order.observers.subject_changed!
order.observers.notify(:canceled)  # nada acontecerá, pois não há observadores vinculados (observers.attach)
```

**Destaques do exemplo anterior:**

Para evitar um comportamento indesejado, você precisa marcar o "subject" (sujeito) como alterado antes de notificar seus observadores sobre algum evento.

Você pode fazer isso ao usar o método `#subject_changed!`. Ele marcará automaticamente o sujeito como alterado.

Mas se você precisar aplicar alguma condicional para marcar uma mudança, você pode usar o método `#subject_changed`. Exemplo: `observers.subject_changed(name != new_name)`

O método `#notify` sempre requer um evento para fazer uma transmissão. Portanto, se você tentar usá-lo sem nenhum evento, você obterá uma exceção.

```ruby
order.observers.notify
# ArgumentError (no events (expected at least 1))
```

[⬆️ Voltar para o índice](#índice-)

### Compartilhando um contexto com seus observadores

Para compartilhar um valor de contexto (qualquer tipo de objeto Ruby) com um ou mais observadores, você precisará usar a palavra-chave `:context` como o último argumento do método `#attach`. Este recurso oferece a você uma oportunidade única de compartilhar um valor no momento de anexar um _observer_.

Quando o método do observer receber dois argumentos, o primeiro será o sujeito e o segundo uma instância `Micro::Observers::Event` que terá o valor do contexto.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.subject_changed!
    observers.notify(:canceled)
    self
  end
end

module OrderEvents
  def self.canceled(order, event)
    puts "The order #(#{order.object_id}) has been canceled. (from: #{event.context[:from]})"  # event.ctx é um alias para event.context
  end
end

order = Order.new
order.observers.attach(OrderEvents, context: { from: 'example #2' })  # anexando vários observadores. Exemplo: observers.attach(A, B, context: {hello:: world})
order.cancel!
# A mensagem abaixo será impressa pelo observador (OrderEvents):
# The order #(70196221441820) has been canceled. (from: example #2)
```

[⬆️ Voltar para o índice](#índice-)

### Compartilhando dados ao notificar os observadores

Como mencionado anteriormente, o [`event context`](#compartilhando-um-contexto-com-seus-observadores) é um valor armazenado quando você anexa seu _observer_. Mas, às vezes, será útil enviar alguns dados adicionais ao transmitir um evento aos seus _observers_. O `event data` dá a você esta oportunidade única de compartilhar algum valor no momento da notificação.

```ruby
class Order
  include Micro::Observers
end

module OrderHandler
  def self.changed(order, event)
    puts "The order #(#{order.object_id}) received the number #{event.data} from #{event.ctx[:from]}."
  end
end

order = Order.new
order.observers.attach(OrderHandler, context: { from: 'example #3' })
order.observers.subject_changed!
order.observers.notify(:changed, data: 1)

# A mensagem abaixo será impressa pelo observador (OrderHandler):
# The order #(70196221441820) received the number 1 from example #3.
```

[⬆️ Voltar para o índice](#índice-)

### O que é `Micro::Observers::Event`?

O `Micro::Observers::Event` é o payload do evento. Veja abaixo todas as suas propriedades:

- `#name` será o evento transmitido.
- `#subject` será o sujeito observado.
- `#context` serão [os dados de contexto](#compartilhando-um-contexto-com-seus-observadores) que foram definidos no momento em que você anexa o _observer_.
- `#data` será [o valor compartilhado na notificação dos observadores](#compartilhando-dados-ao-notificar-os-observadores).
- `#ctx` é um apelido para o método `#context`.
- `#subj` é um _alias_ para o método `#subject`.

[⬆️ Voltar para o índice](#índice-)

### Usando um callable como um observador

O método `observers.on()` permite que você anexe um callable (objeto que responda ao método `call`) como um observador.

Normalmente, um callable tem uma responsabilidade bem definida (faz apenas uma coisa), por isso, tende a ser mais amigável com o [SRP (princípio de responsabilidade única)](https://en.wikipedia.org/wiki/Single-responsibility_principle) do que um observador convencional (que poderia ter N métodos para responder a diferentes tipos de notificação).

Este método recebe as opções abaixo:

1. `:event` o nome do evento esperado.
2. `:call` o próprio callable.
3. `:with` (opcional) pode definir o valor que será usado como argumento do objeto callable. Portanto, se for um `Proc`, uma instância de `Micro::Observers::Event` será recebida como o argumento `Proc` e sua saída será o argumento que pode ser chamado. Mas se essa opção não for definida, a instância `Micro::Observers::Event` será o argumento do callable.
4. `:context` serão os dados de contexto que foram definidos no momento em que você anexa o _observer_.

```ruby
class Person
  include Micro::Observers

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def name=(new_name)
    return unless observers.subject_changed(new_name != @name)

    @name = new_name

    observers.notify(:name_has_been_changed)
  end
end

PrintPersonName = -> (data) do
  puts("Person name: #{data.fetch(:person).name}, number: #{data.fetch(:number)}")
end

person = Person.new('Aristóteles')

person.observers.on(
  event: :name_has_been_changed,
  call: PrintPersonName,
  with: -> event { {person: event.subject, number: event.context} },
  context: rand
)

person.name = 'Coutinho'

# A mensagem abaixo será impressa pelo observador (PrintPersonName):
# Person name: Coutinho, number: 0.5018509191706862
```

[⬆️ Voltar para o índice](#índice-)

### Chamando os observadores

Você pode usar um callable (uma classe, módulo ou objeto que responda ao método `call`) para ser seu _observer_. Para fazer isso, você só precisa usar o método `#call` em vez de `#notify`.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.subject_changed!
    observers.call # na prática, este é um alias para observers.notify(:call)
    self
  end
end

OrderCancellation = -> (order) { puts "The order #(#{order.object_id}) has been canceled." }

order = Order.new
order.observers.attach(OrderCancellation)
order.cancel!

# A mensagem abaixo será impressa pelo observador (OrderCancellation):
# The order #(70196221441820) has been canceled.
```

> **Nota**: O `observers.call` pode receber um ou mais eventos, mas no caso de receber eventos/argumentos, o evento padrão (`call`) não será transmitido.

[⬆️ Voltar para o índice](#índice-)

### Notificar observadores sem marcá-los como alterados

Este recurso deve ser usado com cuidado!

Se você usar os métodos `#notify!` ou `#call!` você não precisará marcar observers com `#subject_changed`.

[⬆️ Voltar para o índice](#índice-)

### Definindo observers que executam apenas uma vez

Existem duas formas de anexar um observer e definir que ele executará apenas uma vez.

A primeira forma de fazer isso é passando a opção `perform_once: true` para o método `observers.attach()`. Exemplo:

#### `observers.attach(*args, perform_once: true)`

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

module OrderNotifications
  def self.canceled(order)
    puts "The order #(#{order.object_id}) has been canceled."
  end
end

order = Order.new
order.observers.attach(OrderNotifications, perform_once: true) # you can also pass an array of observers with this option

order.observers.some? # true
order.cancel!         # The order #(70291642071660) has been canceled.

order.observers.some? # false
order.cancel!         # Nothing will happen because there aren't observers.
```

#### `observers.once(event:, call:, ...)`

A segunda forma de conseguir isso é usando o método `observers.once()` que tem a mesma API do [`observers.on()`](#usando-um-callable-como-um-observador). Mas a diferença é que o método `#once()` removerá o observer após a sua execução.

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

module NotifyAfterCancel
  def self.call(event)
    puts "The order #(#{event.subject.object_id}) has been canceled."
  end
end

order = Order.new
order.observers.once(event: :canceled, call: NotifyAfterCancel)

order.observers.some? # true
order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # false
order.cancel!         # Nothing will happen because there aren't observers.
```

[⬆️ Voltar para o índice](#índice-)

### Definindo observers com blocos

Os métodos `#on()` e `#once()` podem receber um evento (a `symbol`) e um bloco para definir observers.

#### `observers.on()`

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

order = Order.new
order.observers.on(:canceled) do |event|
  puts "The order #(#{event.subject.object_id}) has been canceled."
end

order.observers.some? # true

order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # true
```

#### `observers.once()`

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

order = Order.new
order.observers.once(:canceled) do |event|
  puts "The order #(#{event.subject.object_id}) has been canceled."
end

order.observers.some? # true

order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # false
```

#### Substituindo um bloco por um `lambda`/`proc`

Ruby permite que você substitua qualquer bloco com um `lambda`/`proc`. Portanto, será possível usar este tipo de recurso para definir seus observers. Exemplo:

```ruby
class Order
  include Micro::Observers

  def cancel!
    observers.notify!(:canceled)
  end
end

NotifyAfterCancel = -> event { puts "The order #(#{event.subject.object_id}) has been canceled." }

order = Order.new
order.observers.once(:canceled, &NotifyAfterCancel)

order.observers.some? # true
order.cancel!         # The order #(70301497466060) has been canceled.

order.observers.some? # false
order.cancel!         # Nothing will happen because there aren't observers.
```

[⬆️ Voltar para o índice](#índice-)

### Desanexando observers

Como mostrado no primeiro exemplo, você pode usar o `observers.detach()` para remove observers.

Mas, existe uma alternativa a esse método que permite remover objetos observers ou remover callables pelo nome de seus eventos. O método para fazer isso é: `observers.off()`.

```ruby
class Order
  include Micro::Observers
end

NotifyAfterCancel = -> {}

module OrderNotifications
  def self.canceled(_order)
  end
end

order = Order.new
order.observers.on(:canceled) { |_event| }
order.observers.on(event: :canceled, call: NotifyAfterCancel)
order.observers.attach(OrderNotifications)

order.observers.some? # true
order.observers.count # 3

order.observers.off(:canceled) # removing the callable (NotifyAfterCancel).
order.observers.some? # true
order.observers.count # 1

order.observers.off(OrderNotifications)
order.observers.some? # false
order.observers.count # 0
```

[⬆️ Voltar para o índice](#índice-)

### Integrações ActiveRecord e ActiveModel

Para fazer uso deste recurso, você precisa de um módulo adicional.

Exemplo de Gemfile:

```ruby
gem 'u-observers', require: 'u-observers/for/active_record'
```

Este recurso irá expor módulos que podem ser usados ​​para adicionar macros (métodos estáticos) que foram projetados para funcionar com os callbacks do `ActiveModel`/`ActiveRecord`. Exemplo:

#### `.notify_observers_on()`

O `notify_observers_on` permite que você defina um ou mais callbacks do `ActiveModel`/`ActiveRecord`, que serão usados ​​para notificar seus _observers_.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  notify_observers_on(:after_commit) # usando vários callbacks. Exemplo: notificar_observadores_on(:before_save, :after_commit)

  # O método acima faz o mesmo que o exemplo comentado abaixo.
  #
  # after_commit do | record |
  #   record.subject_changed!
  #   record.notify (:after_commit)
  # end
end

module TitlePrinter
  def self.after_commit(post)
    puts "Title: #{post.title}"
  end
end

module TitlePrinterWithContext
  def self.after_commit(post, event)
    puts "Title: #{post.title} (from: #{event.context[:from]})"
  end
end

Post.transaction do
  post = Post.new(title: 'Hello world')
  post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'example #6' })
  post.save
end

# A mensagem abaixo será impressa pelos observadores (TitlePrinter, TitlePrinterWithContext):
# Title: Hello world
# Title: Hello world (de: exemplo # 6)
```

[⬆️ Voltar para o índice](#índice-)

#### Anexando observers no nível da classe (`.notify_observers!()`)

Enquanto o `notify_observers_on` apenas conecta o callback a um broadcast (você ainda precisa chamar `attach` em cada instância), o `notify_observers!` também **vincula os _observers_ ao modelo no nível da classe** através da opção obrigatória `with:` — assim você nunca chama `observers.attach`. A opção `event:` nomeia o callback a ser usado; use `context:` para encaminhar um contexto para esses _observers_, e passe qualquer opção extra (por exemplo, `on:`) diretamente para o callback subjacente.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  # Anexa TitlePrinter (e TitlePrinterWithContext) em todo after_commit
  # disparado por um update — sem precisar de `observers.attach` por instância.
  notify_observers!(
    on: :update,
    with: [TitlePrinter, TitlePrinterWithContext],
    event: :after_commit,
    context: { from: 'class-level' }
  )

  # Equivalente a:
  #
  # after_commit(on: :update) do |record|
  #   record.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'class-level' })
  #   record.observers.subject_changed!
  #   record.observers.notify(:after_commit)
  # end
end

Post.transaction { Post.create(title: 'Hello world') } # nada — `on: :update`

post = Post.first
Post.transaction { post.update(title: 'Hello again') }
# Title: Hello again
# Title: Hello again (de: class-level)
```

> **Nota**: `event:` e `with:` são obrigatórios (`with:` aceita um único _observer_ ou um array). Sem _observers_ para anexar, use o `notify_observers_on`.

Os _observers_ declarados são inspecionáveis e removíveis no nível da classe:

```ruby
Post.observers_to_notify
# { after_commit: [TitlePrinter, TitlePrinterWithContext] }

# Para de notificar um dado observer (de todos os callbacks, ou use `from:` para limitar)
Post.detach_observers_to_notify(TitlePrinterWithContext)
# { after_commit: [TitlePrinter] }

Post.detach_observers_to_notify(TitlePrinter, from: :after_commit)
# {}

# Sem observers, remove o(s) callback(s) por completo:
Post.detach_observers_to_notify(from: :after_commit)
```

[⬆️ Voltar para o índice](#índice-)

#### `.notify_observers()`

O `notify_observers` permite definir um ou mais eventos, que serão utilizados para notificar após a execução de algum callback do `ActiveModel`/`ActiveRecord`.

```ruby
class Post < ActiveRecord::Base
  include ::Micro::Observers::For::ActiveRecord

  after_commit(&notify_observers(:transaction_completed))

  # O método acima faz o mesmo que o exemplo comentado abaixo.
  #
  # after_commit do | record |
  # record.subject_changed!
  # record.notify (:transaction_completed)
  # end
end

module TitlePrinterWithContext
  def self.transaction_completed(post, event)
    puts("Title: #{post.title} (from: #{event.ctx[:from]})")
  end
end

Post.transaction do
  post = Post.new(title: 'Olá mundo')

  post.observers.on(:transaction_completed) { |event| puts("Title: #{event.subject.title}") }

  post.observers.attach(TitlePrinterWithContext, context: { from: 'example #7' })

  post.save
end

# A mensagem abaixo será impressa pelos observadores (TitlePrinter, TitlePrinterWithContext):
# Title: Olá mundo
# Title: Olá mundo (from: example # 5)
```

> **Observação**: você pode usar `include ::Micro::Observers::For::ActiveModel` se sua classe apenas fizer uso do `ActiveModel` e todos os exemplos anteriores funcionarão.

[⬆️ Voltar para o índice](#índice-)

## Desenvolvimento

Depois de verificar o repositório, execute `bin/setup` para instalar as dependências. Em seguida, execute `rake test` para executar os testes. Você também pode executar `bin/console` um prompt interativo que permitirá que você experimente.

Para instalar esta gem em sua máquina local, execute `bundle exec rake install`. Para lançar uma nova versão, atualize o número da versão em `version.rb` e execute `bundle exec rake release`, que criará uma tag git para a versão, envie os commits ao git e envie e envie o arquivo `.gem` para [rubygems.org](https://rubygems.org).

## Contribuindo

Reportar bugs e solicitações de pull-requests são bem-vindos no GitHub em https://github.com/u-gems/u-observers. Este projeto pretende ser um espaço seguro e acolhedor para colaboração, e espera-se que os colaboradores sigam o [código de conduta](https://github.com/u-gems/u-observers/blob/master/CODE_OF_CONDUCT.md).

## License

A gem está disponível como código aberto sob os termos da [Licença MIT](https://opensource.org/licenses/MIT).

## Código de conduta

Espera-se que todos que interagem nas bases de código do projeto `Micro::Observers`, rastreadores de problemas, salas de bate-papo e listas de discussão sigam o [código de conduta](https://github.com/u-gems/u-observers/blob/master/CODE_OF_CONDUCT.md).
