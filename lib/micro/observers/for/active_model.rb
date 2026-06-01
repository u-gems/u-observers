# frozen_string_literal: true

module Micro
  module Observers
    module For

      module ActiveModel
        module ClassMethods
          def notify_observers_proc(events)
            proc do |object|
              object.observers.subject_changed!
              object.observers.send(:broadcast_if_subject_changed, events)
            end
          end

          def notify_observers(*events)
            notify_observers_proc(Event::Names.fetch(events))
          end

          def notify_observers_on(*callback_methods)
            Utils::Arrays.fetch_from_args(callback_methods).each do |callback_method|
              self.public_send(callback_method, &notify_observers_proc([callback_method]))
            end
          end

          NO_OBSERVERS_TO_NOTIFY_MSG =
            'no observers (expected at least one observer in `with:`)'.freeze

          NO_EVENT_TO_NOTIFY_MSG =
            'no event (expected a callback name in `event:`)'.freeze

          def notify_observers!(event:, with:, context: nil, **callback_options)
            observers = Utils::Arrays.flatten_and_compact(with)

            raise ArgumentError, NO_OBSERVERS_TO_NOTIFY_MSG if observers.empty?

            events = Utils::Arrays.flatten_and_compact(event)

            raise ArgumentError, NO_EVENT_TO_NOTIFY_MSG if events.empty?

            events.each do |callback_method|
              register_observers_to_notify(callback_method, observers, context)

              install_observers_to_notify_callback(callback_method, callback_options)
            end
          end

          # Introspection: the observers declared via `notify_observers!`, keyed
          # by the callback they fire on. e.g. { after_commit: [TitlePrinter] }
          def observers_to_notify
            __observers_to_notify.each_with_object({}) do |(event, entries), result|
              result[event] = entries.map { |observer, _context| observer } unless entries.empty?
            end
          end

          # Remove previously declared observers. Without `from:` they are
          # removed from every callback; pass `from:` (a callback name or an
          # array of them) to scope it. With no observers, clears the callback(s).
          def detach_observers_to_notify(*observers, from: nil)
            observers = Utils::Arrays.flatten_and_compact(observers)
            events = from ? Utils::Arrays.flatten_and_compact(from) : __observers_to_notify.keys

            events.each do |event|
              entries = __observers_to_notify[event]

              next unless entries

              if observers.empty?
                __observers_to_notify.delete(event)
              else
                entries.reject! { |observer, _context| observers.include?(observer) }
                __observers_to_notify.delete(event) if entries.empty?
              end
            end

            observers_to_notify
          end

          def register_observers_to_notify(event, observers, context)
            entries = (__observers_to_notify[event] ||= [])

            observers.each do |observer|
              entries << [observer, context] unless entries.any? { |existing, _| existing == observer }
            end
          end

          def install_observers_to_notify_callback(event, callback_options)
            installed = __observers_to_notify_callbacks

            return if installed[event]

            installed[event] = true

            declaring_class = self

            callback_block = proc do |record|
              declaring_class.send(:notify_registered_observers, record, event)
            end

            if callback_options.empty?
              self.public_send(event, &callback_block)
            else
              self.public_send(event, **callback_options, &callback_block)
            end
          end

          def notify_registered_observers(record, event)
            entries = __observers_to_notify[event]

            return if entries.nil? || entries.empty?

            set = record.observers

            entries.each do |observer, context|
              context ? set.attach(observer, context: context) : set.attach(observer)
            end

            set.subject_changed!
            set.send(:broadcast_if_subject_changed, [event])
          end

          def __observers_to_notify
            @__observers_to_notify ||= {}
          end

          def __observers_to_notify_callbacks
            @__observers_to_notify_callbacks ||= {}
          end

          private_constant :NO_OBSERVERS_TO_NOTIFY_MSG, :NO_EVENT_TO_NOTIFY_MSG
        end

        def self.included(base)
          base.extend(ClassMethods)
          base.send(
            :private_class_method,
            :notify_observers_proc,
            :register_observers_to_notify,
            :install_observers_to_notify_callback,
            :notify_registered_observers,
            :__observers_to_notify,
            :__observers_to_notify_callbacks
          )
          base.send(:include, ::Micro::Observers)
        end
      end

    end
  end
end
