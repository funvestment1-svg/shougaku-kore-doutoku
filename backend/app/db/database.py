from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from app.config import get_settings

settings = get_settings()

_is_sqlite = settings.database_url.startswith("sqlite")

# SQLite doesn't support connection pooling parameters
_engine_kwargs: dict = {
    "echo": settings.debug,
    "future": True,
}
if not _is_sqlite:
    _engine_kwargs.update({
        "pool_pre_ping": True,
        "pool_size": 10,
        "max_overflow": 20,
    })

engine = create_async_engine(settings.database_url, **_engine_kwargs)

AsyncSessionLocal = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False,
)


async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()
