require 'test_helper'

if ACTIVERECORD_AVAILABLE
  class Micro::Observers::For::ActiveRecordTest < Minitest::Test
    def setup
      MemoryOutput.clear
    end

    class Book < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_on(:after_commit)
    end

    module LogTheBookCreation
      def self.after_commit(book)
        MemoryOutput.puts("The book was successfully created! Title: #{book.title}")
      end
    end

    def test_the_observer_notification
      Book.transaction do
        book = Book.new(title: 'Observers')
        book.observers.attach(LogTheBookCreation)
        book.save
      end

      assert_equal(
        ['The book was successfully created! Title: Observers'],
        MemoryOutput.history
      )
    end

    class Post < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_on(:after_commit)
    end

    module TitlePrinter
      def self.after_commit(post)
        MemoryOutput.puts("Title: #{post.title}")
      end
    end

    module TitlePrinterWithContext
      def self.after_commit(post, event)
        MemoryOutput.puts("Title: #{post.title}, from: #{event.context[:from]}")
      end
    end

    def test_the_observer_notification_including_a_context
      Post.transaction do
        post = Post.new(title: 'Hello world')
        post.observers.attach(TitlePrinter, TitlePrinterWithContext, context: { from: 'Test 1' })
        post.save
      end

      assert_equal(
        [
          'Title: Hello world',
          'Title: Hello world, from: Test 1'
        ], MemoryOutput.history
      )
    end

    # Declarative form: `notify_observers_event` binds the observers to the
    # model at the class level via `with:`, so callers no longer need to
    # `attach` them on every instance.

    class Law < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_event(:after_commit, with: TitlePrinter)
    end

    def test_observers_declared_at_the_class_level
      Law.transaction { Law.create(title: 'Foo') }

      assert_equal(['Title: Foo'], MemoryOutput.history)
    end

    class Album < ActiveRecord::Base
      include ::Micro::Observers::For::ActiveRecord

      notify_observers_event(
        :after_commit,
        with: [TitlePrinter, TitlePrinterWithContext],
        context: { from: 'studio' },
        on: :update
      )
    end

    def test_class_level_observers_with_context_and_a_callback_option
      album = nil

      # `on: :update` is forwarded to the AR callback, so create notifies nothing.
      Album.transaction { album = Album.create(title: 'Bar') }

      assert_equal([], MemoryOutput.history)

      Album.transaction { album.update(title: 'Baz') }

      # `context:` reaches the observers — TitlePrinterWithContext sees `from: studio`.
      assert_equal(
        [
          'Title: Baz',
          'Title: Baz, from: studio'
        ], MemoryOutput.history
      )
    end

    def test_notify_observers_event_requires_observers
      error = assert_raises(ArgumentError) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'laws'

          include ::Micro::Observers::For::ActiveRecord

          notify_observers_event(:after_commit, with: nil)
        end
      end

      assert_equal('no observers (expected at least one observer in `with:`)', error.message)
    end
  end
end
