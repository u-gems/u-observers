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
              callback_block = attach_and_notify_observers_proc(callback_method, observers, context)

              if callback_options.empty?
                self.public_send(callback_method, &callback_block)
              else
                self.public_send(callback_method, **callback_options, &callback_block)
              end
            end
          end

          def attach_and_notify_observers_proc(event, observers, context)
            events = [event]

            proc do |object|
              set = object.observers

              context ? set.attach(*observers, context: context) : set.attach(*observers)

              set.subject_changed!
              set.send(:broadcast_if_subject_changed, events)
            end
          end

          private_constant :NO_OBSERVERS_TO_NOTIFY_MSG, :NO_EVENT_TO_NOTIFY_MSG
        end

        def self.included(base)
          base.extend(ClassMethods)
          base.send(:private_class_method, :notify_observers_proc, :attach_and_notify_observers_proc)
          base.send(:include, ::Micro::Observers)
        end
      end

    end
  end
end
