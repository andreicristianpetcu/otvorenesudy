# encoding: utf-8

class SpecialHearing < Hearing
  include Hearing::Scoped.to('Špecializovaného trestného súdu')
  default_scope apply
end
