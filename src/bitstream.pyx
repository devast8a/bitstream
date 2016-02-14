import cython

cdef int64 UNIT_SIZE = 8
cdef int64 UNIT_OFFSET = UNIT_SIZE - 1

cdef class State:
    def __init__(State self, BitStream stream):
        self.offsetRead = stream.offsetRead
        self.offsetWrite = stream.offsetWrite
        self.stream = stream

class ReadError(Exception):
    def __init__(self, message):
        Exception.__init__(self, message)

cdef class BitStream:
    def __init__(self, stream = None):
        self.database = defaultFactory.database
        
        if stream == None:
            self.stream = []
            self.offsetRead = 0
            self.offsetWrite = 0
        else:
            self.stream = stream
            self.offsetRead = 0
            self.offsetWrite = len(stream) * 8

    def __len__(self):
        return self.offsetWrite - self.offsetRead

    cpdef write(BitStream self, value, type key):
        cdef TypeInfo typeinfo = self.database[key]
        cdef validator = typeinfo.validator
        cdef writer = typeinfo.writer
        cdef int64 byte
        cdef int64 bit

        if validator and not validator(value):
            raise Exception("Input did not validate")

        byte = self.offsetWrite / UNIT_SIZE
        bit = self.offsetWrite % UNIT_SIZE

        writer(self, value, byte, bit)

        # Advance pointer
        self.offsetWrite += typeinfo.length

    cpdef read(BitStream self, type key, int length):
        cdef TypeInfo typeinfo = self.database[key]
        cdef State state
        cdef int64 byte
        cdef int64 bit

        # Allow the reader to read an arbitrary number of bits
        #   from the stream, in order to properly recover we save
        #   our state and restore it in the event of an exception
        #   or other failure.
        if typeinfo.length == -1:
            state = self.save()

            output = []
            try:
                for i in range(length):
                    output.append(typeinfo.reader(self))
            except:
                self.restore(state)
                raise

        # If the reader knows ahead of time how much data it will consume
        #  we can take control of the pointers instead.
        else:
            # Check if we're going to read more data than is available
            if self.offsetRead + (typeinfo.length * length) > self.offsetWrite:
                raise ReadError("end of stream")

            for i in range(length):
                byte = self.offsetRead / UNIT_SIZE
                bit = self.offsetRead % UNIT_SIZE

                output = typeinfo.reader(self, byte, bit)

                # Advance pointer
                self.offsetRead += typeinfo.length

                return output

    cpdef readInt(BitStream self, int size, int length = 1):
        pass

    cpdef void seek(BitStream self, int64 offset):
        self.offsetRead += offset

    cpdef State save(BitStream self):
        return State(self)

    cpdef void restore(BitStream self, State state):
        if state.stream != self:
            raise Exception("State is not registered to this bitstream")

        self.offsetRead = state.offsetRead
        self.offsetWrite = state.offsetWrite

cdef class TypeInfo:
    def __init__(
        TypeInfo self,
        object key,
        int32 length = -1,
        reader = None,
        validator = None,
        writer = None,
    ):
        self.key = key
        self.length = length
        self.reader = reader
        self.writer = writer
        self.validator = validator

cdef class BitStreamFactory:
    def __init__(self):
        self.database = {}

    cpdef void register(BitStreamFactory self, TypeInfo typeinfo):
        self.database[typeinfo.key] = typeinfo
        return

cdef BitStreamFactory defaultFactory = BitStreamFactory()
