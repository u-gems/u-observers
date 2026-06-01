# frozen_string_literal: true

module Micro
  module Observers
    module For

      module ActiveModel
        module ClassMethods
          def notify_observers!(events)
            proc do |object|
              object.observers.subject_changed!
              object.observers.send(:broadcast_if_subject_changed, events)
            end
          end

          def notify_observers(*events)
            notify_observers!(Event::Names.fetch(events))
          end

          def notify_observers_on(*callback_methods, with: nil, context: nil, **callback_options)
            observers = Utils::Arrays.flatten_and_compact(with)

            Utils::Arrays.fetch_from_args(callback_methods).each do |callback_method|
              callback_block =
                if observers.empty?
                  notify_observers!([callback_method])
                else
                  attach_and_notify_observers!(callback_method, observers, context)
                end

              if callback_options.empty?
                self.public_send(callback_method, &callback_block)
              else
                self.public_send(callback_method, **callback_options, &callback_block)
              end
            end
          end

          def attach_and_notify_observers!(callback_method, observers, context)
            events = [callback_method]

            proc do |object|
              set = object.observers

              context ? set.attach(*observers, context: context) : set.attach(*observers)

              set.subject_changed!
              set.send(:broadcast_if_subject_changed, events)
            end
          end
        end

        def self.included(base)
          base.extend(ClassMethods)
          base.send(:private_class_method, :notify_observers!, :attach_and_notify_observers!)
          base.send(:include, ::Micro::Observers)
        end
      end

    end
  end
end
